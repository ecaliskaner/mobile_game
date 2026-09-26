import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Chef avatar + rank name + XP bar toward the next rank.
class ChefBadge extends StatelessWidget {
  final String title;
  final double progress;
  const ChefBadge({super.key, required this.title, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2A17), Color(0xFF241708)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC1854A), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFE1B0), Color(0xFFF0A94F), Color(0xFFC97C1F)],
                stops: [0, 0.65, 1],
              ),
              border: Border.all(color: const Color(0xFFF0B429), width: 2),
            ),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.chefHat, size: 18, color: Color(0xFF4A2712)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFFFFF6E6))),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    height: 7,
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFFF0B429), Color(0xFFFFD65C)]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Move counter pill (⇄ number of tiles tapped so far).
class MoveBadge extends StatelessWidget {
  final int moves;
  const MoveBadge({super.key, required this.moves});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2A17), Color(0xFF241708)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC1854A), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.hand, size: 13, color: Color(0xFFFFF6E6)),
          const SizedBox(width: 4),
          Text('$moves',
              style: const TextStyle(color: Color(0xFFF0B429), fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}

/// Round pause button; opens the pause dialog and freezes the timer/taps.
class PauseButton extends StatelessWidget {
  final VoidCallback onTap;
  const PauseButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFF3A2A17), Color(0xFF241708)]),
          border: Border.all(color: const Color(0xFFC1854A), width: 2),
        ),
        alignment: Alignment.center,
        child: const Icon(LucideIcons.pause, size: 15, color: Color(0xFFFFF6E6)),
      ),
    );
  }
}

/// Small tilted ribbon banner naming the "restaurant".
class LogoRibbon extends StatelessWidget {
  const LogoRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.02,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE2622A), Color(0xFFA8441A)]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF0B429), width: 2),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.utensilsCrossed, size: 14, color: Color(0xFFFFF6E2)),
            SizedBox(width: 6),
            Text('Sokak Lezzetleri', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFFFF6E2))),
          ],
        ),
      ),
    );
  }
}
