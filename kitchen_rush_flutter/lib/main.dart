import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/game_screen.dart';

void main() => runApp(const KitchenRushApp());

class KitchenRushApp extends StatelessWidget {
  const KitchenRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE2622A),
      brightness: Brightness.dark,
    );
    final baseTextTheme = ThemeData(brightness: Brightness.dark).textTheme;

    return MaterialApp(
      title: 'Mutfak Telaşı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF1A1108),
        textTheme: GoogleFonts.nunitoTextTheme(baseTextTheme),
        splashFactory: InkRipple.splashFactory,
      ),
      home: const GameScreen(),
    );
  }
}
