import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../game/game_controller.dart';
import '../models/kitchen_tile.dart';
import '../widgets/power_button.dart';
import '../widgets/tile_face.dart';

const _ink = Color(0xFF5A3A1E);
const _accent = Color(0xFFE86A33);

// Logical canvas: board panel on top, tray panel below. The whole canvas is
// scaled with FittedBox, so every tile can fly between board and tray inside
// one Stack via AnimatedPositioned.
const double _canvasWidth = 360;
const double _boardPad = 8;
const double _boardPanelHeight = KitchenRushController.boardHeight + _boardPad * 2;
const double _trayTop = _boardPanelHeight + 16;
const double _trayPanelHeight = 64;
const double _canvasHeight = _trayTop + _trayPanelHeight;
const double _slotStep = KitchenRushController.tileSize + 4;
const double _slotLeft =
    (_canvasWidth - (KitchenRushController.trayCapacity * _slotStep - 4)) / 2;
const double _slotTop = _trayTop + (_trayPanelHeight - KitchenRushController.tileSize) / 2;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final controller = KitchenRushController();
  GameStatus _lastStatus = GameStatus.playing;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onChanged);
    controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final status = controller.status;
    if (status != _lastStatus && status != GameStatus.playing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showResult(status);
      });
    }
    _lastStatus = status;
    setState(() {});
  }

  Future<void> _showResult(GameStatus status) {
    final won = status == GameStatus.won;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFBF4),
        icon: Icon(won ? LucideIcons.partyPopper : LucideIcons.cookingPot, size: 40, color: _accent),
        title: Text(
          won ? 'Seviye ${controller.level} tamam!' : 'Tezgah doldu',
          style: const TextStyle(fontWeight: FontWeight.w900, color: _ink),
        ),
        content: Text(
          won ? 'Bütün malzemeleri topladın.' : '7 göz doldu, eşleşecek üçlü kalmadı.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _ink),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (won)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: () {
                Navigator.of(ctx).pop();
                controller.nextLevel();
              },
              child: const Text('Sonraki seviye'),
            )
          else ...[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                controller.restartLevel();
              },
              child: const Text('Tekrar dene', style: TextStyle(color: _ink)),
            ),
            if (controller.undoLeft > 0)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _accent),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  controller.undo();
                },
                child: Text('Geri al (${controller.undoLeft})'),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF4E6), Color(0xFFFBDDBF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                _TopBar(controller: controller),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          child: SizedBox(
                            width: _canvasWidth,
                            height: _canvasHeight,
                            child: _GameCanvas(controller: controller),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PowerButton(
                            icon: LucideIcons.undo2,
                            label: 'Geri al',
                            count: controller.undoLeft,
                            onPressed: controller.canUndo ? controller.undo : null,
                          ),
                          const SizedBox(width: 16),
                          PowerButton(
                            icon: LucideIcons.shuffle,
                            label: 'Karıştır',
                            count: controller.shuffleLeft,
                            onPressed: controller.canShuffle ? controller.shuffle : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final KitchenRushController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mutfak Telaşı',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink, height: 1.1)),
            Text('Seviye ${controller.level}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _accent)),
          ],
        ),
        const Spacer(),
        _Chip(icon: LucideIcons.layers, label: '${controller.remainingCount}'),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: controller.restartLevel,
          icon: const Icon(LucideIcons.rotateCcw, size: 20),
          style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _ink),
          tooltip: 'Yeniden başla',
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _ink),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
        ],
      ),
    );
  }
}

class _GameCanvas extends StatelessWidget {
  final KitchenRushController controller;
  const _GameCanvas({required this.controller});

  @override
  Widget build(BuildContext context) {
    const size = KitchenRushController.tileSize;
    final boardTiles = controller.tiles.where((t) => t.onBoard).toList()
      ..sort((a, b) => a.layer != b.layer ? a.layer - b.layer : a.y.compareTo(b.y));

    Widget tileAt(KitchenTile tile, double left, double top, {bool covered = false, VoidCallback? onTap}) {
      return AnimatedPositioned(
        key: ValueKey(tile.id),
        duration: KitchenRushController.flightDuration,
        curve: Curves.easeOutCubic,
        left: left,
        top: top,
        width: size,
        height: size,
        child: _Pressable(
          onTap: onTap,
          child: AnimatedScale(
            scale: tile.state == TileState.clearing ? 0 : 1,
            duration: KitchenRushController.clearDuration,
            curve: Curves.easeInBack,
            child: TileFace(type: tile.type, size: size, covered: covered),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: _canvasWidth,
          height: _boardPanelHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF6E3C6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEBCFA5), width: 2),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: _trayTop,
          width: _canvasWidth,
          height: _trayPanelHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF9C6B3F), Color(0xFF7A4F2A)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
          ),
        ),
        for (int i = 0; i < KitchenRushController.trayCapacity; i++)
          Positioned(
            left: _slotLeft + i * _slotStep,
            top: _slotTop,
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(size * 0.24),
              ),
            ),
          ),
        for (final tile in boardTiles)
          () {
            final covered = controller.isCovered(tile);
            return tileAt(
              tile,
              _boardPad + tile.x,
              _boardPad + tile.y,
              covered: covered,
              onTap: covered ? null : () => controller.tap(tile),
            );
          }(),
        for (int i = 0; i < controller.tray.length; i++)
          tileAt(controller.tray[i], _slotLeft + i * _slotStep, _slotTop),
      ],
    );
  }
}

/// Shrinks slightly while pressed so taps feel physical.
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.9 : 1,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}
