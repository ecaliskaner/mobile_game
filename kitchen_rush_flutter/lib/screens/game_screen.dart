import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../game/game_controller.dart';
import '../models/kitchen_tile.dart';
import '../widgets/hud_widgets.dart';
import '../widgets/kitchen_tile_widget.dart';
import '../widgets/order_rail_widget.dart';
import '../widgets/overlays.dart';
import '../widgets/target_sign_widget.dart';
import '../widgets/toolbar_gem_button.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final KitchenRushController controller;
  String? _comboText;
  Timer? _comboHideTimer;
  Timer? _hintTimer;
  String? _hintedTileId;
  bool _gameOverDialogShown = false;

  @override
  void initState() {
    super.initState();
    controller = KitchenRushController();
    controller.onMatch = _handleMatch;
    controller.addListener(_onControllerChanged);
    _hintTimer = Timer.periodic(const Duration(seconds: 6), (_) => _showHint());
  }

  void _onControllerChanged() {
    if (controller.over && !_gameOverDialogShown) {
      _gameOverDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final remaining = controller.tiles.where((t) => !t.removed).length;
        showGameOverDialog(
          context,
          win: controller.isWin,
          title: controller.isWin ? 'Mutfak Toplandı!' : 'Tezgah Taştı!',
          body: controller.isWin
              ? '${controller.chefTitle.name} olarak ${controller.elapsedSeconds} saniyede '
                  '${controller.moves} hamlede topladın. Skor: ${controller.score}'
              : 'Sipariş rayı doldu. Skor: ${controller.score} · Kalan malzeme: $remaining',
          onRestart: () {
            Navigator.of(context, rootNavigator: true).pop();
            setState(() {
              _gameOverDialogShown = false;
              controller.newGame();
            });
          },
        );
      });
    }
    setState(() {});
  }

  void _handleMatch(int comboCount, int bonus) {
    if (comboCount >= 2) {
      setState(() {
        _comboText = comboCount >= 5 ? '🔥🔥 x$comboCount MUTFAK ATEŞİ!' : '🔥 x$comboCount Kombo!';
      });
      _comboHideTimer?.cancel();
      _comboHideTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _comboText = null);
      });
    }
  }

  void _showHint() {
    if (controller.over || controller.paused) return;
    final clickable = controller.tiles.where((t) => !t.removed && !controller.isCovered(t)).toList();
    if (clickable.isEmpty) return;
    clickable.shuffle();
    setState(() => _hintedTileId = clickable.first.id);
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _hintedTileId = null);
    });
  }

  void _openPause() {
    controller.setPaused(true);
    showPauseDialog(
      context,
      onResume: () {
        controller.setPaused(false);
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    _comboHideTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = controller.tiles.where((t) => !t.removed).length;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ChefBadge(title: controller.chefTitle.name, progress: controller.titleProgress)),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MoveBadge(moves: controller.moves),
                          PauseButton(onTap: _openPause),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const LogoRibbon(),
                  const SizedBox(height: 8),
                  TargetSignWidget(targets: controller.targetTypes, remainingOf: controller.remainingOf),
                  const SizedBox(height: 8),
                  _StatRow(controller: controller, remaining: remaining),
                  const SizedBox(height: 8),
                  _Board(controller: controller, hintedTileId: _hintedTileId),
                  const SizedBox(height: 8),
                  _RailCard(tray: controller.tray),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ToolbarGemButton(
                        icon: LucideIcons.shuffle,
                        label: 'Karıştır',
                        badgeCount: controller.shuffleLeft,
                        disabled: controller.shuffleLeft <= 0 || controller.over,
                        onTap: controller.shuffleBoard,
                      ),
                      const SizedBox(width: 14),
                      ToolbarGemButton(
                        icon: LucideIcons.undo2,
                        label: 'Geri Al',
                        badgeCount: controller.undoLeft,
                        disabled: controller.undoLeft <= 0 || controller.over,
                        onTap: controller.undoLast,
                      ),
                      const SizedBox(width: 14),
                      ToolbarGemButton(
                        icon: LucideIcons.settings,
                        label: 'Ayarlar',
                        light: const Color(0xFF9D9D9D),
                        base: const Color(0xFF5E5E5E),
                        dark: const Color(0xFF3A3A3A),
                        onTap: () => showHelpDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.sparkles, size: 14, color: Color(0xFFF0D9B0)),
                      SizedBox(width: 5),
                      Text('Afiyet olsun, Şef!', style: TextStyle(fontSize: 13, color: Color(0xFFF0D9B0))),
                    ],
                  ),
                ],
              ),
            ),
            IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _comboText != null ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _comboText ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26, color: Color(0xFFFF8A3D)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final KitchenRushController controller;
  final int remaining;
  const _StatRow({required this.controller, required this.remaining});

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value, {Color? valueColor}) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF1),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8A6B47), letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor ?? const Color(0xFF3A2712))),
              ],
            ),
          ),
        );
    return Row(
      children: [
        stat('KALAN', '$remaining'),
        stat('SKOR', '${controller.score}'),
        stat('KOMBO', controller.comboCount >= 2 ? '🔥x${controller.comboCount}' : '—', valueColor: const Color(0xFFFF8A3D)),
        stat('SÜRE', '${controller.elapsedSeconds}s'),
      ],
    );
  }
}

class _Board extends StatelessWidget {
  final KitchenRushController controller;
  final String? hintedTileId;
  const _Board({required this.controller, required this.hintedTileId});

  @override
  Widget build(BuildContext context) {
    const boardW = KitchenRushController.boardWidth;
    const boardH = KitchenRushController.boardHeight;

    final board = Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF8A5C2C),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: boardW,
          height: boardH,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFFFF7E6), Color(0xFFECD6A6)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: Stack(
            children: controller.tiles.where((t) => !t.removed).map((tile) {
              final covered = controller.isCovered(tile);
              return Positioned(
                left: tile.x,
                top: tile.y,
                child: KitchenTileWidget(
                  tile: tile,
                  size: KitchenRushController.tileSize,
                  covered: covered,
                  hinted: tile.id == hintedTileId,
                  onTap: () => controller.onTileTap(tile),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    // Scale the fixed-size board down on narrow phones without breaking hit-testing.
    return Center(child: FittedBox(fit: BoxFit.scaleDown, child: board));
  }
}

class _RailCard extends StatelessWidget {
  final List<TrayItem> tray;
  const _RailCard({required this.tray});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFE7E2D8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: OrderRailWidget(tray: tray),
    );
  }
}
