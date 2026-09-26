import 'dart:math';

import 'package:flutter/material.dart';

import '../models/kitchen_tile.dart';
import 'ingredient_glyph.dart';

/// Draws a dashed (empty slot) or solid (filled slot) ring — a small
/// custom widget instead of a plain [Border], matching the order-rail
/// look from the reference art.
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final bool solid;
  const DashedCirclePainter({required this.color, this.solid = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    if (solid) {
      canvas.drawOval(rect, paint);
      return;
    }
    const dashCount = 14;
    const dashAngle = (2 * pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * dashAngle, dashAngle * 0.6, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.solid != solid;
}

/// The 7-slot "order rail" tray. A slot glows red once only one empty
/// slot remains, warning the player before an overflow game-over.
class OrderRailWidget extends StatelessWidget {
  final List<TrayItem> tray;
  final int maxSlots;
  const OrderRailWidget({super.key, required this.tray, this.maxSlots = 7});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxSlots, (i) {
        final item = i < tray.length ? tray[i] : null;
        final danger = tray.length >= maxSlots - 1 && item == null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: SizedBox(
            width: 37,
            height: 37,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(37, 37),
                  painter: DashedCirclePainter(
                    color: danger ? const Color(0xFFC8402F) : const Color(0xFFD8BD8B),
                    solid: item != null,
                  ),
                ),
                if (item != null)
                  Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFFAF1)),
                  ),
                if (item != null) IngredientGlyph(type: item.type, size: 20),
              ],
            ),
          ),
        );
      }),
    );
  }
}
