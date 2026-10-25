import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/data/roster_seed.dart';
import '../../domain/models/card_definition.dart';
import '../../domain/models/enums.dart';
import '../../state/collection_controller.dart';
import '../../state/game_controllers.dart';
import '../../theme/aetherium_theme.dart';
import '../widgets/card_art.dart';
import '../widgets/rarity_badge.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = cardById(cardId);
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RELIC')),
        body: const Center(child: Text('Card not found.')),
      );
    }

    final teamAsync = ref.watch(teamProvider);
    final team = teamAsync.value ?? const <String>[];
    final inTeam = team.contains(card.id);
    final teamFull = team.length >= kBattleTeamSize;
    final accent = rarityAccent(card.rarity);
    final ownedState = ref.watch(collectionProvider).value?.byId(card.id);
    final owned = ownedState?.owned == true;
    final level = ownedState?.level ?? 0;
    final copies = ownedState?.copies ?? 0;
    final copiesToNext = ownedState?.copiesToNext;

    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 360,
            backgroundColor: AetheriumColors.surfaceLowest,
            title: Text(
              'RELIC PROFILE',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CardArt(
                    card: card,
                    borderRadius: 0,
                    fit: BoxFit.cover,
                    showNameFallback: false,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          AetheriumColors.surface.withValues(alpha: 0.2),
                          AetheriumColors.surface,
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${card.faction.label.toUpperCase()}  //  ${card.role.label.toUpperCase()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                letterSpacing: 0.08,
                                fontWeight: FontWeight.w700,
                                color: AetheriumColors.secondary,
                              ),
                            ),
                            const Spacer(),
                            RarityBadge(rarity: card.rarity),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          owned ? card.name : 'LOCKED RELIC',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            color: AetheriumColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          owned
                              ? 'LV $level  ·  ${card.displayEpithet}'
                              : 'Unlock via Astral Exchange chests.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            height: 1.3,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (card.displayQuote.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AetheriumColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AetheriumColors.secondary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '"${card.displayQuote}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: AetheriumColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _sectionTitle('DOSSIER'),
                const SizedBox(height: 8),
                if (card.displayOrigin.isNotEmpty)
                  _metaRow('ORIGIN', card.displayOrigin),
                _metaRow('FACTION', card.faction.label),
                _metaRow('ROLE', card.role.label),
                _metaRow(
                  'TAGS',
                  card.synergyTags.isEmpty
                      ? 'None'
                      : card.synergyTags.join(' · '),
                ),
                const SizedBox(height: 16),
                _sectionTitle('STORY'),
                const SizedBox(height: 8),
                Text(
                  card.displayStory,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.55,
                    color: AetheriumColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('COMBAT MATRIX'),
                const SizedBox(height: 8),
                _combatMatrix(card),
                const SizedBox(height: 20),
                _sectionTitle('TACTICAL SKILL KIT'),
                const SizedBox(height: 8),
                _skillCard(
                  label: 'INHERENT PASSIVE',
                  name: card.passiveName,
                  body: card.passiveDescription,
                  accent: AetheriumColors.primary,
                ),
                const SizedBox(height: 8),
                _skillCard(
                  label: 'TACTICAL ACTIVE',
                  name: card.active.name,
                  body: card.active.description,
                  accent: AetheriumColors.secondary,
                  trailing:
                      'EN ${card.active.enCost}  ·  CD ${card.active.cooldownTurns}',
                ),
                if (owned) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('ASCENSION'),
                  const SizedBox(height: 8),
                  Text(
                    copiesToNext == null
                        ? 'Max level reached. Copies banked: $copies'
                        : 'Copies $copies / $copiesToNext to reach LV ${level + 1}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AetheriumColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: copiesToNext == null || copies < copiesToNext
                        ? null
                        : () async {
                            final err = await ref
                                .read(collectionProvider.notifier)
                                .levelUp(card.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(err ?? 'Leveled up ${card.name}.'),
                              ),
                            );
                          },
                    child: const Text('LEVEL UP'),
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: !owned
                      ? null
                      : () async {
                          final notifier = ref.read(teamProvider.notifier);
                          if (inTeam) {
                            await notifier.remove(card.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${card.name} removed from squad.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          if (teamFull) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Squad is full. Remove a fighter first.',
                                ),
                              ),
                            );
                            return;
                          }
                          final ok = await notifier.add(card.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? '${card.name} added to squad.'
                                      : 'Could not add ${card.name}.',
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(
                    !owned
                        ? 'LOCKED'
                        : (inTeam ? 'REMOVE FROM SQUAD' : 'ADD TO SQUAD'),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.08,
        color: AetheriumColors.primary,
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.04,
                color: AetheriumColors.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.35,
                color: AetheriumColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _combatMatrix(CardDefinition card) {
    final s = card.stats;
    final items = [
      ('HP VITALITY', s.hp, AetheriumColors.hp),
      ('ARMOR / DEF', s.def, AetheriumColors.secondary),
      ('ATK', s.atk, AetheriumColors.tertiary),
      ('SPD', s.spd, AetheriumColors.primary),
      ('EN', s.en, AetheriumColors.secondaryContainer),
      ('COMBAT POWER', card.powerDisplay, AetheriumColors.tertiary),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        return Container(
          width: 158,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AetheriumColors.surfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: e.$3.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.$1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  letterSpacing: 0.05,
                  color: AetheriumColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${e.$2}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: e.$3,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _skillCard({
    required String label,
    required String name,
    required String body,
    required Color accent,
    String? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AetheriumColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        letterSpacing: 0.06,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AetheriumColors.secondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.45,
              color: AetheriumColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
