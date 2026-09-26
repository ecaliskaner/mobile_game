import 'package:flutter/material.dart';

import '../models/ingredient.dart';
import 'ingredient_glyph.dart';

/// A chunky rounded-square tile: cream face, darker "thickness" edge
/// underneath, ingredient glyph in the middle. Covered tiles go grey so the
/// playable ones on top read instantly.
class TileFace extends StatelessWidget {
  final IngredientType type;
  final double size;
  final bool covered;

  const TileFace({super.key, required this.type, required this.size, this.covered = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: covered ? const Color(0xFFD8CFC1) : const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: covered ? const Color(0xFFC2B7A5) : const Color(0xFFF0E1C6)),
        boxShadow: [
          BoxShadow(
            color: covered ? const Color(0xFFA99C87) : const Color(0xFFD9BC8C),
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: covered ? 0.08 : 0.16),
            blurRadius: 6,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: covered ? 0.4 : 1,
        child: IngredientGlyph(type: type, size: size * 0.64),
      ),
    );
  }
}
