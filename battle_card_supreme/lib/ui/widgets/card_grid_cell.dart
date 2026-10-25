import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/card_definition.dart';
import '../../theme/aetherium_theme.dart';
import 'card_art.dart';
import 'rarity_badge.dart';

/// Vault cell: portrait + name (+ level). Locked cards are silhouetted.
class CardGridCell extends StatelessWidget {
  const CardGridCell({
    super.key,
    required this.card,
    this.onTap,
    this.selected = false,
    this.owned = true,
    this.level = 0,
  });

  final CardDefinition card;
  final VoidCallback? onTap;
  final bool selected;
  final bool owned;
  final int level;

  @override
  Widget build(BuildContext context) {
    final accent = rarityAccent(card.rarity);
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
                  : accent.withValues(alpha: owned ? 0.4 : 0.2),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    owned
                        ? CardArt(
                            card: card,
                            borderRadius: 7,
                            fit: BoxFit.cover,
                            showNameFallback: false,
                          )
                        : ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              0.15, 0.15, 0.15, 0, 0,
                              0.15, 0.15, 0.15, 0, 0,
                              0.15, 0.15, 0.15, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                            child: CardArt(
                              card: card,
                              borderRadius: 7,
                              fit: BoxFit.cover,
                              showNameFallback: false,
                            ),
                          ),
                    if (!owned)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.lock,
                          color: AetheriumColors.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    if (owned)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AetheriumColors.surfaceLowest
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LV $level',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AetheriumColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: RarityBadge(rarity: card.rarity, compact: true),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 5, 4, 6),
                child: Text(
                  owned ? card.name : '???',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: owned
                        ? AetheriumColors.onSurface
                        : AetheriumColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
