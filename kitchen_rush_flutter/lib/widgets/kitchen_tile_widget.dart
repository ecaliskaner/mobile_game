import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/kitchen_tile.dart';
import 'ingredient_glyph.dart';

/// Ring color per stack layer — bronze (bottom) → sky → sage → gold (top),
/// so the pyramid's depth reads at a glance even before anything is tapped.
const _layerRingColors = [
  Color(0xFFC9915A),
  Color(0xFF7FB8D9),
  Color(0xFF8FCF8A),
  Color(0xFFF0B429),
];

/// One tile on the cutting board: a plate disc + ingredient glyph, ringed
/// by its layer color. Covered tiles get a frosted "steam" overlay and
/// stop accepting taps; a [hinted] tile pulses a gold outline.
class KitchenTileWidget extends StatelessWidget {
  final KitchenTile tile;
  final double size;
  final bool covered;
  final VoidCallback? onTap;
  final bool hinted;

  const KitchenTileWidget({
    super.key,
    required this.tile,
    required this.size,
    required this.covered,
    required this.onTap,
    this.hinted = false,
  });

  @override
  Widget build(BuildContext context) {
    final ring = _layerRingColors[tile.layer.clamp(0, _layerRingColors.length - 1)];
    return GestureDetector(
      onTap: covered ? null : onTap,
      child: AnimatedScale(
        scale: 1 + tile.layer * 0.045,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (hinted)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.15),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeInOut,
                  builder: (context, v, _) => Transform.scale(
                    scale: v,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF0B429), width: 2.5),
                      ),
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: covered
                        ? const [Color(0xFFCFC9BB), Color(0xFFA9A291), Color(0xFF8F8878)]
                        : const [Color(0xFFFFFDF7), Color(0xFFF2E3C2), Color(0xFFE3CB9B)],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                  border: Border.all(color: ring, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
              ),
              Opacity(
                opacity: covered ? 0.5 : 1,
                child: IngredientGlyph(type: tile.type, size: size * 0.62),
              ),
              if (covered)
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
                    child: Container(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
