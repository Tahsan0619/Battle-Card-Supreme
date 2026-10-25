import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/card_definition.dart';
import '../../domain/models/enums.dart';
import '../../theme/aetherium_theme.dart';
import 'card_art.dart';
import 'rarity_badge.dart';

class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.card,
    this.onTap,
    this.selected = false,
    this.trailing,
    this.compact = false,
  });

  final CardDefinition card;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = rarityAccent(card.rarity);
    final artW = compact ? 44.0 : 56.0;
    final artH = compact ? 52.0 : 64.0;
    final pad = compact ? 8.0 : 10.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: AetheriumColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AetheriumColors.primary
                  : accent.withValues(alpha: 0.45),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Row(
              children: [
                CardArt(
                  card: card,
                  width: artW,
                  height: artH,
                  borderRadius: 6,
                ),
                SizedBox(width: compact ? 8 : 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w600,
                                fontSize: compact ? 13 : 15,
                                color: AetheriumColors.onSurface,
                                height: 1.1,
                              ),
                            ),
                          ),
                          RarityBadge(rarity: card.rarity, compact: true),
                        ],
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      Text(
                        '${card.role.label}  ·  ${card.faction.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: compact ? 10 : 11,
                          height: 1.1,
                          color: AetheriumColors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: compact ? 3 : 6),
                      Text(
                        compact
                            ? 'HP ${card.stats.hp}  ATK ${card.stats.atk}  DEF ${card.stats.def}'
                            : 'HP ${card.stats.hp}  ATK ${card.stats.atk}  DEF ${card.stats.def}  SPD ${card.stats.spd}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: compact ? 10 : 11,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: AetheriumColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 2),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
