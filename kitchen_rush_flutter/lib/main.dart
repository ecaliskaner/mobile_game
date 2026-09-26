import 'package:flutter/material.dart';

import 'screens/game_screen.dart';

void main() => runApp(const KitchenRushApp());

class KitchenRushApp extends StatelessWidget {
  const KitchenRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mutfak Telaşı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE86A33)),
      ),
      home: const GameScreen(),
    );
  }
}
