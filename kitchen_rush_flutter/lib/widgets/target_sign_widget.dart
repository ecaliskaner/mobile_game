import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/ingredient.dart';
import 'ingredient_glyph.dart';

/// A hanging wooden sign listing 3 "focus" ingredients and how many of
/// each remain on the board — purely informational (win/lose is still
/// deciding by clearing everything), but gives the player a mid-round
/// goal to track.
class TargetSignWidget extends StatelessWidget {
  final List<IngredientType> targets;
  final int Function(IngredientType) remainingOf;

  const TargetSignWidget({super.key, required this.targets, required this.remainingOf});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD9A765), Color(0xFF8A5C2C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6B431E), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.target, size: 13, color: Color(0xFFFFF2D8)),
              SizedBox(width: 5),
              Text('HEDEF MALZEMELER',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFFFFF2D8), letterSpacing: 0.4)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: targets.map((t) {
              final remain = remainingOf(t);
              final done = remain == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFFDF7), Color(0xFFF2E3C2), Color(0xFFE3CB9B)],
                          stops: [0, 0.65, 1],
                        ),
                        border: Border.all(color: done ? const Color(0xFF4F8C46) : Colors.transparent, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: done
                          ? const Icon(LucideIcons.check, size: 18, color: Color(0xFF4F8C46))
                          : IngredientGlyph(type: t, size: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      done ? 'Tamam' : '$remain',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: done ? const Color(0xFF9BE08E) : const Color(0xFFFFF2D8),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
