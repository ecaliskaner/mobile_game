import 'ingredient.dart';

/// One physical tile stacked on the cutting board.
class KitchenTile {
  final String id;
  final IngredientType type;
  final int layer;
  double x;
  double y;
  bool removed;

  KitchenTile({
    required this.id,
    required this.type,
    required this.layer,
    required this.x,
    required this.y,
    this.removed = false,
  });
}

/// A single occupant of the order rail (the 7-slot tray).
class TrayItem {
  final String id;
  final IngredientType type;
  const TrayItem(this.id, this.type);
}

/// One rung on the chef-title ladder, unlocked by cumulative score.
class ChefTitleTier {
  final int minScore;
  final String name;
  const ChefTitleTier(this.minScore, this.name);
}

const List<ChefTitleTier> kChefTitles = [
  ChefTitleTier(0, 'Çırak Aşçı'),
  ChefTitleTier(150, 'Kalfa Aşçı'),
  ChefTitleTier(400, 'Şef'),
  ChefTitleTier(800, 'Usta Şef'),
];
