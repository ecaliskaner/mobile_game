import 'ingredient.dart';

enum TileState { board, tray, clearing, cleared }

class KitchenTile {
  final String id;
  final IngredientType type;
  final int layer;
  double x;
  double y;
  TileState state;

  KitchenTile({
    required this.id,
    required this.type,
    required this.layer,
    required this.x,
    required this.y,
    this.state = TileState.board,
  });

  bool get onBoard => state == TileState.board;
}

class LevelConfig {
  final int typeCount;
  final int setsPerType;
  final List<int> layerCounts;

  const LevelConfig({required this.typeCount, required this.setsPerType, required this.layerCounts});

  int get totalTiles => typeCount * setsPerType * 3;

  static LevelConfig forLevel(int level) {
    switch (level) {
      case 1:
        return const LevelConfig(typeCount: 5, setsPerType: 2, layerCounts: [18, 12]);
      case 2:
        return const LevelConfig(typeCount: 6, setsPerType: 3, layerCounts: [26, 18, 10]);
      default:
        return const LevelConfig(typeCount: 8, setsPerType: 3, layerCounts: [30, 22, 14, 6]);
    }
  }
}
