import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

ShapeBorder _cardShape() => RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

Widget _bigActionButton(String label, VoidCallback onPressed) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE2622A),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      elevation: 0,
    ),
    onPressed: onPressed,
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

void showGameOverDialog(
  BuildContext context, {
  required bool win,
  required String title,
  required String body,
  required VoidCallback onRestart,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFFFFAF1),
      shape: _cardShape(),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFFFDF7), Color(0xFFF2E3C2), Color(0xFFE3CB9B)],
                  stops: [0, 0.65, 1],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                win ? LucideIcons.partyPopper : LucideIcons.flame,
                size: 30,
                color: win ? const Color(0xFF4F8C46) : const Color(0xFFC8402F),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: win ? const Color(0xFF4F8C46) : const Color(0xFFC8402F),
              ),
            ),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8A6B47), fontSize: 13.5)),
            const SizedBox(height: 16),
            _bigActionButton('Yeni Mutfak', onRestart),
          ],
        ),
      ),
    ),
  );
}

void showPauseDialog(BuildContext context, {required VoidCallback onResume}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFFFFAF1),
      shape: _cardShape(),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.pause, size: 40, color: Color(0xFF8A6B47)),
            const SizedBox(height: 10),
            const Text('Mola Verildi',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF3A2712))),
            const SizedBox(height: 6),
            const Text('Tezgah bekliyor, hazır olduğunda devam et.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8A6B47), fontSize: 13)),
            const SizedBox(height: 16),
            _bigActionButton('Devam Et', onResume),
          ],
        ),
      ),
    ),
  );
}

class _HelpLine extends StatelessWidget {
  final String text;
  const _HelpLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: Color(0xFF8A6B47), fontWeight: FontWeight.w800)),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF8A6B47), fontSize: 13))),
        ],
      ),
    );
  }
}

void showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFFFFAF1),
      shape: _cardShape(),
      title: const Text('Nasıl Oynanır', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFA8441A))),
      content: const SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpLine('Sadece üstü açık malzemelere dokunabilirsin.'),
            _HelpLine('Dokunduğun malzeme sipariş rayına gider (en fazla 7 göz).'),
            _HelpLine('Aynı malzemeden 3 tane ray\'e gelince otomatik eşleşir.'),
            _HelpLine('Ray 7 gözü doldurup eşleşme olmazsa oyun biter.'),
            _HelpLine('Karıştır kalan malzemeleri yeniden dağıtır, Geri Al son hamleni geri çeker.'),
            _HelpLine('Art arda hızlı eşleşmeler Kombo bonus puanı verir.'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Anladım')),
      ],
    ),
  );
}
