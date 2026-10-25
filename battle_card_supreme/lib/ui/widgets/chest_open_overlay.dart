import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/aetherium_theme.dart';
import 'card_art.dart';

/// Full-screen chest open: shake → burst → staggered reward reveal.
Future<void> showChestOpenOverlay({
  required BuildContext context,
  required String chestCode,
  required String chestTitle,
  required List<Map<String, dynamic>> results,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Chest open',
    barrierColor: Colors.black.withValues(alpha: 0.82),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim, secondary) {
      return _ChestOpenOverlay(
        chestCode: chestCode,
        chestTitle: chestTitle,
        results: results,
        entrance: anim,
      );
    },
  );
}

class _ChestOpenOverlay extends StatefulWidget {
  const _ChestOpenOverlay({
    required this.chestCode,
    required this.chestTitle,
    required this.results,
    required this.entrance,
  });

  final String chestCode;
  final String chestTitle;
  final List<Map<String, dynamic>> results;
  final Animation<double> entrance;

  @override
  State<_ChestOpenOverlay> createState() => _ChestOpenOverlayState();
}

class _ChestOpenOverlayState extends State<_ChestOpenOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _shake;
  late final AnimationController _burst;
  late final AnimationController _reveal;
  bool _opened = false;
  bool _canClose = false;

  static const _chestArt = {
    'dock_crate': 'assets/brand/chests/chest_dock_crate.jpg',
    'brine_cache': 'assets/brand/chests/chest_brine_cache.jpg',
    'gale_reliquary': 'assets/brand/chests/chest_gale_reliquary.jpg',
    'eclipse_casket': 'assets/brand/chests/chest_eclipse_casket.jpg',
    'sovereign_reliquary': 'assets/brand/chests/chest_sovereign_reliquary.jpg',
  };

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _reveal = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 420 + widget.results.length * 220,
      ),
    );
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _shake.forward();
    if (!mounted) return;
    setState(() => _opened = true);
    await _burst.forward();
    if (!mounted) return;
    await _reveal.forward();
    if (!mounted) return;
    setState(() => _canClose = true);
  }

  @override
  void dispose() {
    _shake.dispose();
    _burst.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = _chestArt[widget.chestCode] ??
        'assets/brand/chests/chest_dock_crate.jpg';
    final canClose = _canClose || widget.results.isEmpty;

    return FadeTransition(
      opacity: widget.entrance,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Text(
                  widget.chestTitle.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: AetheriumColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _opened ? 'RELICS UNSEALED' : 'RESONATING…',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AetheriumColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_opened)
                        AnimatedBuilder(
                          animation: _burst,
                          builder: (context, _) {
                            final o = (1 - _burst.value).clamp(0.0, 1.0);
                            return Opacity(
                              opacity: o,
                              child: Transform.scale(
                                scale: 1 + _burst.value * 2.4,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AetheriumColors.secondary
                                          .withValues(alpha: o),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      AnimatedBuilder(
                        animation: Listenable.merge([_shake, _burst]),
                        builder: (context, child) {
                          final t = _shake.value;
                          final shake =
                              (1 - t) * math.sin(t * math.pi * 10) * 10;
                          final scale = _opened
                              ? 1.0 +
                                  Curves.easeOutBack
                                          .transform(_burst.value) *
                                      0.18
                              : 0.92 + t * 0.08;
                          final glow = _opened
                              ? 0.35 + _burst.value * 0.55
                              : 0.15 + t * 0.2;
                          return Transform.translate(
                            offset: Offset(shake, 0),
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AetheriumColors.primary
                                          .withValues(alpha: glow),
                                      blurRadius: 48 + _burst.value * 40,
                                      spreadRadius: 4 + _burst.value * 12,
                                    ),
                                    BoxShadow(
                                      color: AetheriumColors.secondary
                                          .withValues(alpha: glow * 0.55),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Image.asset(
                          art,
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2,
                            size: 96,
                            color: AetheriumColors.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 148,
                  child: AnimatedBuilder(
                    animation: _reveal,
                    builder: (context, _) {
                      if (!_opened) {
                        return const SizedBox.shrink();
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < widget.results.length; i++)
                              _RewardChip(
                                result: widget.results[i],
                                progress: _reveal.value,
                                index: i,
                                total: widget.results.length,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed:
                      canClose ? () => Navigator.of(context).pop() : null,
                  child: Text(canClose ? 'CLAIM' : 'OPENING…'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.result,
    required this.progress,
    required this.index,
    required this.total,
  });

  final Map<String, dynamic> result;
  final double progress;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final start = total <= 1 ? 0.0 : index / total;
    final end = total <= 1 ? 1.0 : ((index + 1) / total).clamp(0.0, 1.0);
    final local = ((progress - start) / (end - start)).clamp(0.0, 1.0);
    final card = (result['card'] as Map?)?.cast<String, dynamic>() ?? {};
    final id = card['id'] as String? ?? '';
    final name = card['name'] as String? ?? 'Relic';
    final neu = result['was_new'] == true;

    return Opacity(
      opacity: Curves.easeOut.transform(local),
      child: Transform.translate(
        offset: Offset(0, (1 - local) * 28),
        child: Transform.scale(
          scale: 0.7 + local * 0.3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: neu
                          ? AetheriumColors.tertiary
                          : AetheriumColors.outlineVariant,
                      width: neu ? 2 : 1,
                    ),
                    boxShadow: neu
                        ? [
                            BoxShadow(
                              color: AetheriumColors.tertiary
                                  .withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: id.isEmpty
                      ? const ColoredBox(
                          color: AetheriumColors.surfaceHigh,
                          child: Icon(Icons.style,
                              color: AetheriumColors.primary),
                        )
                      : Image.asset(
                          CardArt.assetPathFor(id),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: AetheriumColors.surfaceHigh,
                            child: Center(
                              child: Text(
                                (name.length >= 2
                                        ? name.substring(0, 2)
                                        : name)
                                    .toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
                                  color: AetheriumColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 72,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: AetheriumColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  neu ? 'NEW' : 'COPY',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: neu
                        ? AetheriumColors.tertiary
                        : AetheriumColors.secondary,
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
