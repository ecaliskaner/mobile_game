import 'package:flutter/material.dart';

/// A round, gem-style power-up button with a badge counting remaining
/// uses — Karıştır (shuffle), Geri Al (undo), Ayarlar (settings).
class ToolbarGemButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badgeCount;
  final bool disabled;
  final VoidCallback onTap;
  final Color light;
  final Color base;
  final Color dark;

  const ToolbarGemButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
    this.disabled = false,
    this.light = const Color(0xFF6FA4FF),
    this.base = const Color(0xFF3B6FD1),
    this.dark = const Color(0xFF2A4F9C),
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Column(
        children: [
          GestureDetector(
            onTap: disabled ? null : onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [light, base, dark], stops: const [0, 0.55, 1]),
                    border: Border.all(color: const Color(0xFFF0B429), width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 5))],
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                if (badgeCount != null)
                  Positioned(
                    bottom: -6,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F8C46),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 19),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Color(0xFFFFF6E6), fontWeight: FontWeight.w800, fontSize: 10)),
        ],
      ),
    );
  }
}
