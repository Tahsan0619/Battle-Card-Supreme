import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/data/roster_seed.dart';
import '../../domain/models/enums.dart';
import '../../state/game_controllers.dart';
import '../../theme/aetherium_theme.dart';
import '../widgets/rarity_badge.dart';

class BattlePrepScreen extends ConsumerWidget {
  const BattlePrepScreen({
    super.key,
    required this.onFight,
    required this.onEditSquad,
    required this.onBack,
  });

  final VoidCallback onFight;
  final VoidCallback onEditSquad;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider);
    final mode = ref.watch(activeModeProvider);

    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text('BATTLE PREPARATION'),
      ),
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Squad load failed: $e')),
        data: (ids) {
          final error = ref.read(teamProvider.notifier).validate(ids);
          final cards = cardsByIds(ids);
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  mode.title.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    letterSpacing: 0.08,
                    fontWeight: FontWeight.w700,
                    color: AetheriumColors.secondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mode.waves > 1
                      ? 'Confirm lineup. Survive ${mode.waves} escalating waves.'
                      : 'Confirm lineup before the rift opens.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rules v${mode.ruleVersion} · ${mode.maxRounds} rounds'
                  '${mode.waves > 1 ? ' · ${mode.healBetweenWavesPercent}% heal between waves' : ''}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AetheriumColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                if (error != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AetheriumColors.errorContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error,
                      style: GoogleFonts.plusJakartaSans(
                        color: AetheriumColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: kBattleTeamSize,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      if (i >= cards.length) {
                        return Container(
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AetheriumColors.surfaceLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AetheriumColors.outlineVariant,
                            ),
                          ),
                          child: Text(
                            'EMPTY SLOT',
                            style: GoogleFonts.spaceGrotesk(
                              color: AetheriumColors.outline,
                            ),
                          ),
                        );
                      }
                      final c = cards[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AetheriumColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: rarityAccent(c.rarity).withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${c.role.label}  ·  HP ${c.stats.hp}  ATK ${c.stats.atk}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AetheriumColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            RarityBadge(rarity: c.rarity, compact: true),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                OutlinedButton(
                  onPressed: onEditSquad,
                  child: const Text('EDIT SQUAD'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: error != null
                      ? null
                      : () {
                          final match = ref.read(matchProvider.notifier);
                          final String? startError;
                          if (mode.code == 'survival_challenge') {
                            match.clearSurvivalCarry();
                            ref.read(survivalRunProvider.notifier).begin(mode);
                            startError = match.startSurvivalWave(playerIds: ids);
                          } else {
                            match.clearSurvivalCarry();
                            startError = match.startVsAi(
                              playerIds: ids,
                              mode: mode,
                            );
                          }
                          if (startError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(startError)),
                            );
                            return;
                          }
                          onFight();
                        },
                  child: Text(
                    mode.waves > 1
                        ? 'OPEN THE RIFT  ·  SURVIVE'
                        : 'OPEN THE RIFT  ·  FIGHT',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
