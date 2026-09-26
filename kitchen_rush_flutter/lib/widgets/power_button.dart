import 'package:flutter/material.dart';

/// Pill-shaped power-up button with a small remaining-uses badge.
class PowerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback? onPressed;

  const PowerButton({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.45,
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE86A33),
              disabledBackgroundColor: const Color(0xFFE86A33),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -4,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE86A33), width: 2),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFE86A33)),
            ),
          ),
        ),
      ],
    );
  }
}
