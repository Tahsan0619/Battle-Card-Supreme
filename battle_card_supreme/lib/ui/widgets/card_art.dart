import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/card_definition.dart';
import '../../theme/aetherium_theme.dart';
import 'rarity_badge.dart';

/// Resolves generated portrait assets under `assets/art/portraits/{id}.png`.
class CardArt extends StatelessWidget {
  const CardArt({
    super.key,
    required this.card,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.showNameFallback = true,
  });

  final CardDefinition card;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final bool showNameFallback;

  static String assetPathFor(String cardId) =>
      'assets/art/portraits/$cardId.jpg';

  @override
  Widget build(BuildContext context) {
    final accent = rarityAccent(card.rarity);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          assetPathFor(card.id),
          fit: fit,
          errorBuilder: (_, __, ___) => _Fallback(
            card: card,
            accent: accent,
            showName: showNameFallback,
          ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.card,
    required this.accent,
    required this.showName,
  });

  final CardDefinition card;
  final Color accent;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AetheriumColors.surfaceLowest,
            accent.withValues(alpha: 0.55),
            AetheriumColors.surfaceHigh,
          ],
        ),
      ),
      child: Center(
        child: Text(
          showName && card.name.isNotEmpty
              ? card.name.substring(0, 1).toUpperCase()
              : '?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AetheriumColors.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Brand mark from Design Prefer / Logo.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 36,
    this.square = false,
  });

  final double height;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final path = square
        ? 'assets/brand/bcs_logo_square.png'
        : 'assets/brand/bcs_logo.png';
    return Image.asset(
      path,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Text(
        'BCS',
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: AetheriumColors.primary,
        ),
      ),
    );
  }
}
