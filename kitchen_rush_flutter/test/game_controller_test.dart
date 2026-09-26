import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_rush/game/game_controller.dart';
import 'package:kitchen_rush/models/ingredient.dart';
import 'package:kitchen_rush/models/kitchen_tile.dart';

KitchenRushController _controller() => KitchenRushController(rng: Random(7), animate: false);

KitchenTile _freeTileOf(KitchenRushController c, IngredientType type, {Set<String> skip = const {}}) {
  // Put a fresh, uncovered tile of [type] on top of the board for the test.
  final tile = c.tiles.firstWhere((t) => t.onBoard && t.type == type && !skip.contains(t.id));
  final topLayer = c.tiles.map((t) => t.layer).reduce(max);
  final idx = c.tiles.indexOf(tile);
  c.tiles[idx] = KitchenTile(id: tile.id, type: tile.type, layer: topLayer + 1, x: tile.x, y: tile.y);
  return c.tiles[idx];
}

void main() {
  test('a new tile is inserted next to its own type', () {
    final c = _controller();
    final types = c.tiles.map((t) => t.type).toSet().toList();
    final a = types[0], b = types[1];

    c.tap(_freeTileOf(c, a));
    c.tap(_freeTileOf(c, b));
    final secondA = _freeTileOf(c, a, skip: c.tray.map((t) => t.id).toSet());
    c.tap(secondA);

    expect(c.tray.map((t) => t.type).toList(), [a, a, b]);
  });

  test('two A, one B, then A clears the three A tiles, which were adjacent', () {
    final c = _controller();
    final types = c.tiles.map((t) => t.type).toSet().toList();
    final a = types[0], b = types[1];

    for (final type in [a, a, b]) {
      c.tap(_freeTileOf(c, type, skip: c.tray.map((t) => t.id).toSet()));
    }
    expect(c.tray.map((t) => t.type).toList(), [a, a, b]);

    c.tap(_freeTileOf(c, a, skip: c.tray.map((t) => t.id).toSet()));
    expect(c.tray.map((t) => t.type).toList(), [b]);
  });

  test('covered tiles cannot be tapped', () {
    final c = _controller();
    final covered = c.tiles.firstWhere(c.isCovered);
    c.tap(covered);
    expect(c.tray, isEmpty);
    expect(covered.onBoard, isTrue);
  });

  test('undo never resurrects a tile that was already matched', () {
    final c = _controller();
    final a = c.tiles.first.type;
    for (int i = 0; i < 3; i++) {
      c.tap(_freeTileOf(c, a, skip: c.tray.map((t) => t.id).toSet()));
    }
    expect(c.tray, isEmpty);
    expect(c.canUndo, isFalse);
    c.undo();
    expect(c.tiles.where((t) => t.type == a && t.state == TileState.board).length,
        c.tiles.where((t) => t.type == a).length - 3);
  });

  test('filling seven slots without a triple loses, and undo revives', () {
    final c = _controller();
    final types = c.tiles.map((t) => t.type).toSet().toList();
    final picks = [types[0], types[0], types[1], types[1], types[2], types[2], types[3]];
    for (final type in picks) {
      c.tap(_freeTileOf(c, type, skip: c.tray.map((t) => t.id).toSet()));
    }
    expect(c.status, GameStatus.lost);

    c.undo();
    expect(c.status, GameStatus.playing);
    expect(c.tray.length, 6);
  });

  test('every level deals complete triples and no same-layer overlaps', () {
    for (final level in [1, 2, 3]) {
      final c = _controller()..startLevel(level);
      final counts = <IngredientType, int>{};
      for (final t in c.tiles) {
        counts[t.type] = (counts[t.type] ?? 0) + 1;
      }
      expect(counts.values.every((n) => n % 3 == 0), isTrue);

      for (final a in c.tiles) {
        for (final b in c.tiles) {
          if (identical(a, b) || a.layer != b.layer) continue;
          final overlap = (a.x - b.x).abs() < KitchenRushController.tileSize &&
              (a.y - b.y).abs() < KitchenRushController.tileSize;
          expect(overlap, isFalse, reason: 'level $level layer ${a.layer}');
        }
      }
    }
  });

  test('listeners hear about a landed tile so undo becomes available', () {
    fakeAsync((async) {
      final c = KitchenRushController(rng: Random(7));
      var notified = 0;
      c.addListener(() => notified++);
      c.tap(_freeTileOf(c, c.tiles.first.type));
      expect(c.canUndo, isFalse, reason: 'still flying');
      final before = notified;
      async.elapse(KitchenRushController.flightDuration);
      expect(notified, greaterThan(before));
      expect(c.canUndo, isTrue);
      c.dispose();
    });
  });

  test('shuffle keeps every board tile inside the board', () {
    final c = _controller()..startLevel(3);
    c.shuffle();
    for (final t in c.tiles.where((t) => t.onBoard)) {
      expect(t.x, inInclusiveRange(0, KitchenRushController.boardWidth - KitchenRushController.tileSize));
      expect(t.y, inInclusiveRange(0, KitchenRushController.boardHeight - KitchenRushController.tileSize));
    }
  });
}
