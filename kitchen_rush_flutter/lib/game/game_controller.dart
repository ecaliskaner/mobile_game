import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../models/kitchen_tile.dart';

enum GameStatus { playing, won, lost }

class KitchenRushController extends ChangeNotifier {
  static const double tileSize = 44;
  static const double cell = 50;
  static const double boardWidth = 344;
  static const double boardHeight = 384;
  static const int trayCapacity = 7;
  static const Duration flightDuration = Duration(milliseconds: 260);
  static const Duration clearDuration = Duration(milliseconds: 220);

  final Random _rng;

  /// When false, matches resolve synchronously — used by tests.
  final bool animate;

  int level = 1;
  List<KitchenTile> tiles = [];

  /// Ordered tray contents. Same-type tiles are always kept adjacent, so a
  /// match is always three neighbouring slots.
  final List<KitchenTile> tray = [];
  final Set<String> _arrived = {};
  final List<String> _history = [];
  final List<Timer> _timers = [];

  int undoLeft = 3;
  int shuffleLeft = 2;
  GameStatus status = GameStatus.playing;

  KitchenRushController({Random? rng, this.animate = true}) : _rng = rng ?? Random() {
    startLevel(1);
  }

  int get remainingCount =>
      tiles.where((t) => t.state == TileState.board || t.state == TileState.tray).length;

  int get _activeTrayCount => tray.where((t) => t.state == TileState.tray).length;

  bool get canUndo =>
      status == GameStatus.playing && undoLeft > 0 && _lastUndoableTile() != null;

  bool get canShuffle =>
      status == GameStatus.playing && shuffleLeft > 0 && tiles.any((t) => t.onBoard);

  void startLevel(int newLevel) {
    _cancelTimers();
    level = newLevel;
    final config = LevelConfig.forLevel(level);

    final types = List<IngredientType>.from(IngredientType.values)..shuffle(_rng);
    final deck = <IngredientType>[];
    for (final type in types.take(config.typeCount)) {
      for (int i = 0; i < config.setsPerType * 3; i++) {
        deck.add(type);
      }
    }
    deck.shuffle(_rng);

    final positions = _layout(config.layerCounts);
    tiles = [];
    var cursor = 0;
    for (int layer = 0; layer < positions.length; layer++) {
      for (final pos in positions[layer]) {
        tiles.add(KitchenTile(id: 't$cursor', type: deck[cursor], layer: layer, x: pos.dx, y: pos.dy));
        cursor++;
      }
    }

    tray.clear();
    _arrived.clear();
    _history.clear();
    undoLeft = 3;
    shuffleLeft = 2;
    status = GameStatus.playing;
    notifyListeners();
  }

  void restartLevel() => startLevel(level);

  void nextLevel() => startLevel(level + 1);

  bool isCovered(KitchenTile tile) {
    if (!tile.onBoard) return false;
    for (final other in tiles) {
      if (!other.onBoard || other.layer <= tile.layer) continue;
      if (_overlaps(other.x, other.y, tile.x, tile.y)) return true;
    }
    return false;
  }

  void tap(KitchenTile tile) {
    if (status != GameStatus.playing || !tile.onBoard || isCovered(tile)) return;
    if (_activeTrayCount >= trayCapacity) return;

    final lastSame = tray.lastIndexWhere((t) => t.state == TileState.tray && t.type == tile.type);
    final insertAt = lastSame >= 0 ? lastSame + 1 : tray.length;
    tile.state = TileState.tray;
    tray.insert(insertAt, tile);
    _history.add(tile.id);
    notifyListeners();

    _after(flightDuration, () => _onArrived(tile));
  }

  void _onArrived(KitchenTile tile) {
    if (tile.state != TileState.tray) return;
    _arrived.add(tile.id);

    final match = _findMatch();
    if (match != null) {
      for (final t in match) {
        t.state = TileState.clearing;
        _history.remove(t.id);
      }
      notifyListeners();
      _after(clearDuration, () {
        for (final t in match) {
          t.state = TileState.cleared;
          tray.remove(t);
          _arrived.remove(t.id);
        }
        if (tiles.every((t) => t.state == TileState.cleared)) status = GameStatus.won;
        notifyListeners();
      });
      return;
    }

    final active = tray.where((t) => t.state == TileState.tray).toList();
    final allLanded = active.every((t) => _arrived.contains(t.id));
    if (active.length >= trayCapacity && allLanded) status = GameStatus.lost;
    notifyListeners();
  }

  List<KitchenTile>? _findMatch() {
    final active = tray.where((t) => t.state == TileState.tray).toList();
    for (int i = 0; i + 2 < active.length; i++) {
      final group = active.sublist(i, i + 3);
      final sameType = group.every((t) => t.type == group.first.type);
      final landed = group.every((t) => _arrived.contains(t.id));
      if (sameType && landed) return group;
    }
    return null;
  }

  KitchenTile? _lastUndoableTile() {
    for (int i = _history.length - 1; i >= 0; i--) {
      final tile = tiles.firstWhere((t) => t.id == _history[i]);
      if (tile.state == TileState.tray) return _arrived.contains(tile.id) ? tile : null;
    }
    return null;
  }

  void undo() {
    final revivingFromLoss = status == GameStatus.lost;
    if (revivingFromLoss) status = GameStatus.playing;
    final tile = _lastUndoableTile();
    if (undoLeft <= 0 || tile == null) {
      if (revivingFromLoss) status = GameStatus.lost;
      return;
    }
    tray.remove(tile);
    _arrived.remove(tile.id);
    _history.remove(tile.id);
    tile.state = TileState.board;
    undoLeft--;
    notifyListeners();
  }

  void shuffle() {
    if (!canShuffle) return;
    shuffleLeft--;
    final onBoard = tiles.where((t) => t.onBoard).toList()..shuffle(_rng);
    final maxLayer = onBoard.map((t) => t.layer).reduce(max);
    final byLayer = List.generate(maxLayer + 1, (l) => onBoard.where((t) => t.layer == l).toList());
    final positions = _layout(byLayer.map((l) => l.length).toList());
    for (int l = 0; l < byLayer.length; l++) {
      for (int i = 0; i < byLayer[l].length; i++) {
        byLayer[l][i]
          ..x = positions[l][i].dx
          ..y = positions[l][i].dy;
      }
    }
    notifyListeners();
  }

  /// Lays tiles out mahjong-style: the lowest non-empty layer sits on a
  /// centred grid; each higher tile sits half a cell off a random tile of
  /// the layer below, so it always partially covers something. Tiles in
  /// the same layer never overlap each other.
  List<List<Offset>> _layout(List<int> counts) {
    final layers = <List<Offset>>[];
    List<Offset> below = [];
    for (final count in counts) {
      final placed = <Offset>[];
      for (int i = 0; i < count; i++) {
        placed.add(below.isEmpty ? _gridSpot(placed, count) : _stackedSpot(below, placed));
      }
      layers.add(placed);
      if (placed.isNotEmpty) below = placed;
    }
    return layers;
  }

  Offset _gridSpot(List<Offset> placed, int count) {
    const cols = 7;
    final rows = min((count / cols).ceil() + 1, 7);
    const left = (boardWidth - ((cols - 1) * cell + tileSize)) / 2;
    final top = (boardHeight - ((rows - 1) * cell + tileSize)) / 2;
    final cells = List.generate(cols * rows, (i) => Offset(left + (i % cols) * cell, top + (i ~/ cols) * cell))
      ..shuffle(_rng);
    return cells.firstWhere((c) => _isFree(c, placed), orElse: () => _anyFreeSpot(placed));
  }

  Offset _stackedSpot(List<Offset> below, List<Offset> placed) {
    const h = cell / 2;
    const offsets = [
      Offset(-h, -h), Offset(h, -h), Offset(-h, h), Offset(h, h),
      Offset(0, -h), Offset(0, h), Offset(-h, 0), Offset(h, 0),
    ];
    for (int attempt = 0; attempt < 40; attempt++) {
      final parent = below[_rng.nextInt(below.length)];
      final o = offsets[_rng.nextInt(offsets.length)];
      final spot = Offset(
        (parent.dx + o.dx).clamp(0.0, boardWidth - tileSize),
        (parent.dy + o.dy).clamp(0.0, boardHeight - tileSize),
      );
      if (_isFree(spot, placed)) return spot;
    }
    return _anyFreeSpot(placed);
  }

  Offset _anyFreeSpot(List<Offset> placed) {
    const h = cell / 2;
    final spots = <Offset>[];
    for (double y = 0; y <= boardHeight - tileSize; y += h) {
      for (double x = 0; x <= boardWidth - tileSize; x += h) {
        spots.add(Offset(x, y));
      }
    }
    spots.shuffle(_rng);
    return spots.firstWhere((s) => _isFree(s, placed), orElse: () => spots.first);
  }

  bool _isFree(Offset spot, List<Offset> placed) =>
      placed.every((p) => !_overlaps(p.dx, p.dy, spot.dx, spot.dy));

  static bool _overlaps(double ax, double ay, double bx, double by) =>
      (ax - bx).abs() < tileSize && (ay - by).abs() < tileSize;

  void _after(Duration delay, VoidCallback action) {
    if (!animate) {
      action();
      return;
    }
    final gameLevel = level;
    final gameTiles = tiles;
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (level == gameLevel && identical(tiles, gameTiles)) action();
    });
    _timers.add(timer);
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
