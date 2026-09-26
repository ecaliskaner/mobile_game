import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import 'ingredient_painters.dart';

/// Renders one ingredient's icon: a real Lucide icon where one exists
/// (carrot, meat, egg), otherwise a custom-painted vector glyph. Never
/// emoji, never plain text.
class IngredientGlyph extends StatelessWidget {
  final IngredientType type;
  final double size;

  const IngredientGlyph({super.key, required this.type, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final spec = kIngredientSpecs[type]!;
    if (spec.lucideIcon != null) {
      return Icon(spec.lucideIcon, size: size, color: spec.secondary);
    }
    return CustomPaint(
      size: Size(size, size),
      painter: _painterFor(type),
    );
  }

  CustomPainter _painterFor(IngredientType type) {
    switch (type) {
      case IngredientType.tomato:
        return const TomatoPainter();
      case IngredientType.onion:
        return const OnionPainter();
      case IngredientType.garlic:
        return const GarlicPainter();
      case IngredientType.pepper:
        return const PepperPainter();
      case IngredientType.cheese:
        return const CheesePainter();
      case IngredientType.carrot:
      case IngredientType.meat:
      case IngredientType.egg:
        return const TomatoPainter(); // unreachable: these use lucideIcon above
    }
  }
}
