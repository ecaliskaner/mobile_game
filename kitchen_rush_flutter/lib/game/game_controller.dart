import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import '../models/kitchen_tile.dart';

/// Full game state + rules for Mutfak Telaşı (a Yang Le Ge Yang–style
/// layered matching puzzle), ported from the original HTML/JS prototype.
///
/// Widgets consume this via [ListenableBuilder] / [AnimatedBuilder] — no
/// external state-management package is needed since [ChangeNotifier] is
/// already part of the Flutter SDK.
class KitchenRushController extends ChangeNotifier {
  static const List<int> layerCounts = [30, 22, 14, 6]; // sum = 72 = 8 types * 9
  static const int countPerType = 9;
  static const int trayMax = 7;
  static const double tileSize = 42;
  static const double boardWidth = 356;
  static const double boardHeight = 352;
  static const Duration comboWindow = Duration(milliseconds: 3200);

  final Random _rng = Random();

  List<KitchenTile> tiles = [];
  List<TrayItem> tray = [];
  final List<String> _history = [];

  int shuffleLeft = 2;
  int undoLeft = 3;
  int score = 0;
  int moves = 0;
  int comboCount = 0;
  int lastMatchBonus = 0;
  DateTime? _lastMatchTs;
  DateTime _startTs = DateTime.now();
  int elapsedSeconds = 0;
  bool over = false;
  bool isWin = false;
  bool paused = false;
  List<IngredientType> targetTypes = [];

  /// Fired whenever a triplet resolves, so the UI can show a transient
  /// combo badge / toast without polling every frame.
  void Function(int comboCount, int bonus)? onMatch;

  Timer? _timer;

  KitchenRushController() {
    newGame();
  }

  void newGame() {
    final typeList = <IngredientType>[];
    for (final t in IngredientType.values) {
      for (int i = 0; i < countPerType; i++) {
        typeList.add(t);
      }
    }
    typeList.shuffle(_rng);

    final layerPositions = _genLayerPositions(layerCounts);
    tiles = [];
    int cursor = 0;
    for (int l = 0; l < layerCounts.length; l++) {
      for (int i = 0; i < layerCounts[l]; i++) {
        final pos = layerPositions[l][i];
        tiles.add(KitchenTile(
          id: 't$cursor',
          type: typeList[cursor],
          layer: l,
          x: pos.dx,
          y: pos.dy,
        ));
        cursor++;
      }
    }

    tray = [];
    _history.clear();
    shuffleLeft = 2;
    undoLeft = 3;
    score = 0;
    moves = 0;
    comboCount = 0;
    lastMatchBonus = 0;
    _lastMatchTs = null;
    over = false;
    isWin = false;
    paused = false;
    elapsedSeconds = 0;
    _startTs = DateTime.now();

    final allTypes = List<IngredientType>.from(IngredientType.values)..shuffle(_rng);
    targetTypes = allTypes.take(3).toList();

    _startTimer();
    notifyListeners();
  }

  /// Generates stacked-layer positions: layer 0 sits on a jittered grid,
  /// every tile in layer N+1 is jittered off a random parent tile in layer
  /// N, so higher layers always cover at least one lower tile — the same
  /// "pyramid" trick the HTML prototype uses.
  List<List<Offset>> _genLayerPositions(List<int> counts) {
    final layers = <List<Offset>>[];

    final l0count = counts[0];
    const cols = 6;
    final rows = (l0count / cols).ceil();
    const cellW = (boardWidth - tileSize) / (cols - 1);
    final cellH = (boardHeight - tileSize) / (rows > 1 ? rows - 1 : 1);
    final idxs = List<int>.generate(cols * rows, (i) => i)..shuffle(_rng);
    final l0 = <Offset>[];
    for (int i = 0; i < l0count; i++) {
      final cellIdx = idxs[i];
      final col = cellIdx % cols;
      final row = cellIdx ~/ cols;
      final jx = (_rng.nextDouble() - 0.5) * 10;
      final jy = (_rng.nextDouble() - 0.5) * 10;
      l0.add(Offset(
        (col * cellW + jx).clamp(0, boardWidth - tileSize).toDouble(),
        (row * cellH + jy).clamp(0, boardHeight - tileSize).toDouble(),
      ));
    }
    layers.add(l0);

    for (int l = 1; l < counts.length; l++) {
      final prev = layers[l - 1];
      final cur = <Offset>[];
      for (int i = 0; i < counts[l]; i++) {
        final parent = prev[_rng.nextInt(prev.length)];
        final jx = (_rng.nextDouble() - 0.5) * 26;
        final jy = (_rng.nextDouble() - 0.5) * 26;
        cur.add(Offset(
          (parent.dx + jx).clamp(0, boardWidth - tileSize).toDouble(),
          (parent.dy + jy).clamp(0, boardHeight - tileSize).toDouble(),
        ));
      }
      layers.add(cur);
    }
    return layers;
  }

  bool isCovered(KitchenTile tile) {
    if (tile.removed) return false;
    for (final other in tiles) {
      if (identical(other, tile) || other.removed) continue;
      if (other.layer <= tile.layer) continue;
      if (_overlap(other, tile)) return true;
    }
    return false;
  }

  bool _overlap(KitchenTile a, KitchenTile b) {
    return a.x < b.x + tileSize &&
        a.x + tileSize > b.x &&
        a.y < b.y + tileSize &&
        a.y + tileSize > b.y;
  }

  int remainingOf(IngredientType type) =>
      tiles.where((t) => !t.removed && t.type == type).length;

  void onTileTap(KitchenTile tile) {
    if (over || paused) return;
    if (tray.length >= trayMax) return;
    if (tile.removed || isCovered(tile)) return;

    tile.removed = true;
    moves++;
    tray.add(TrayItem(tile.id, tile.type));
    notifyListeners();
    _resolveTray(tile.id);
  }

  void _resolveTray(String justAddedId) {
    final counts = <IngredientType, int>{};
    for (final it in tray) {
      counts[it.type] = (counts[it.type] ?? 0) + 1;
    }
    IngredientType? matchType;
    for (final entry in counts.entries) {
      if (entry.value >= 3) {
        matchType = entry.key;
        break;
      }
    }

    if (matchType != null) {
      int removedCount = 0;
      final next = <TrayItem>[];
      for (final it in tray) {
        if (it.type == matchType && removedCount < 3) {
          removedCount++;
          continue;
        }
        next.add(it);
      }
      tray = next;

      final now = DateTime.now();
      if (_lastMatchTs != null && now.difference(_lastMatchTs!) < comboWindow) {
        comboCount++;
      } else {
        comboCount = 1;
      }
      _lastMatchTs = now;
      final bonus = comboCount >= 2 ? 30 + (comboCount - 1) * 15 : 30;
      score += bonus;
      lastMatchBonus = bonus;
      notifyListeners();
      onMatch?.call(comboCount, bonus);
      _checkWin();
    } else {
      _history.add(justAddedId);
      notifyListeners();
      if (tray.length >= trayMax) _endGame(false);
    }
  }

  void shuffleBoard() {
    if (shuffleLeft <= 0 || over || paused) return;
    shuffleLeft--;
    final byLayer = List.generate(layerCounts.length, (_) => <KitchenTile>[]);
    for (final t in tiles) {
      if (!t.removed) byLayer[t.layer].add(t);
    }
    final counts = byLayer.map((l) => l.length).toList();
    final newPos = _genLayerPositions(counts);
    for (int l = 0; l < byLayer.length; l++) {
      for (int i = 0; i < byLayer[l].length && i < newPos[l].length; i++) {
        byLayer[l][i].x = newPos[l][i].dx;
        byLayer[l][i].y = newPos[l][i].dy;
      }
    }
    notifyListeners();
  }

  void undoLast() {
    if (undoLeft <= 0 || over || paused || _history.isEmpty) return;
    final lastId = _history.removeLast();
    final tile = tiles.firstWhere((t) => t.id == lastId);
    tile.removed = false;
    final idx = tray.indexWhere((it) => it.id == lastId);
    if (idx >= 0) tray.removeAt(idx);
    undoLeft--;
    notifyListeners();
  }

  void setPaused(bool value) {
    if (over) return;
    paused = value;
    notifyListeners();
  }

  ChefTitleTier get chefTitle {
    var cur = kChefTitles.first;
    for (final t in kChefTitles) {
      if (score >= t.minScore) cur = t;
    }
    return cur;
  }

  double get titleProgress {
    final idx = kChefTitles.indexOf(chefTitle);
    if (idx == kChefTitles.length - 1) return 1.0;
    final next = kChefTitles[idx + 1];
    final span = next.minScore - chefTitle.minScore;
    if (span <= 0) return 1.0;
    return ((score - chefTitle.minScore) / span).clamp(0.0, 1.0);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!over && !paused) {
        elapsedSeconds = DateTime.now().difference(_startTs).inSeconds;
        notifyListeners();
      }
    });
  }

  void _checkWin() {
    final remaining = tiles.where((t) => !t.removed).length;
    if (remaining == 0 && tray.isEmpty) _endGame(true);
  }

  void _endGame(bool win) {
    over = true;
    isWin = win;
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
