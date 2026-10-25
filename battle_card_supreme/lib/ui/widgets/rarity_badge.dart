import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/enums.dart';
import '../../theme/aetherium_theme.dart';

Color rarityAccent(Rarity r) {
  return switch (r) {
    Rarity.common => AetheriumColors.outline,
    Rarity.uncommon => AetheriumColors.success,
    Rarity.rare => AetheriumColors.secondary,
    Rarity.superRare => AetheriumColors.primaryContainer,
    Rarity.epic => const Color(0xFFA855F7),
    Rarity.legendary => AetheriumColors.tertiary,
    Rarity.mythic => const Color(0xFFF472B6),
    Rarity.supreme => const Color(0xFFFFE08A),
  };
}

class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity, this.compact = false});

  final Rarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = rarityAccent(rarity);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.45)],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        compact ? rarity.code : rarity.label.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: AetheriumColors.surfaceLowest,
          letterSpacing: 0.06,
        ),
      ),
    );
  }
}
