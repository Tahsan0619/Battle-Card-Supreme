import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/combat/combat_models.dart';
import '../../domain/modes/mode_rules.dart';
import '../../state/game_controllers.dart';
import '../../theme/aetherium_theme.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({
    super.key,
    required this.onReturnHome,
    required this.onRetry,
    this.onContinueSurvival,
  });

  final VoidCallback onReturnHome;
  final VoidCallback onRetry;
  final VoidCallback? onContinueSurvival;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchProvider);
    final mode = ref.watch(activeModeProvider);
    final survival = ref.watch(survivalRunProvider);

    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('RESULT')),
        body: Center(
          child: FilledButton(
            onPressed: onReturnHome,
            child: const Text('HOME'),
          ),
        ),
      );
    }

    final isSurvival = mode.code == kSurvivalChallenge.code;
    final waveContinue = isSurvival &&
        match.outcome == MatchOutcome.victoryPlayer &&
        survival != null &&
        !survival.complete &&
        onContinueSurvival != null;

    final (title, color, subtitle) = switch (match.outcome) {
      MatchOutcome.victoryPlayer when isSurvival && survival?.complete == true => (
          'SURVIVAL CLEAR',
          AetheriumColors.success,
          'All ${survival?.wavesTotal ?? mode.waves} waves broken. The Rift yields.',
        ),
      MatchOutcome.victoryPlayer when waveContinue => (
          'WAVE CLEARED',
          AetheriumColors.success,
          'Wave ${survival!.cleared}/${survival.wavesTotal} down. Heal applied. Press on.',
        ),
      MatchOutcome.victoryPlayer => (
          'VICTORY',
          AetheriumColors.success,
          'Your squad held the Rift line.',
        ),
      MatchOutcome.victoryEnemy => (
          'DEFEAT',
          AetheriumColors.error,
          isSurvival
              ? 'Fell on wave ${survival?.wave ?? '?'}. Cleared ${survival?.cleared ?? 0}.'
              : 'Tactical debrief: regroup and revise the squad.',
        ),
      MatchOutcome.draw => (
          'DRAW',
          AetheriumColors.tertiary,
          'Turn limit or mutual collapse.',
        ),
      MatchOutcome.forfeitPlayer => (
          'FORFEIT',
          AetheriumColors.outline,
          'You conceded the clash.',
        ),
      MatchOutcome.ongoing => (
          'ONGOING',
          AetheriumColors.secondary,
          'Match still active.',
        ),
    };

    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      appBar: AppBar(
        title: Text(isSurvival ? 'SURVIVAL RESULT' : 'CLASH RESULT'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AetheriumColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AetheriumColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _row('Mode', mode.title),
                  _row('Rules', 'v${mode.ruleVersion}'),
                  _row('Rounds', '${match.round}/${match.maxRounds}'),
                  if (isSurvival)
                    _row(
                      'Waves cleared',
                      '${survival?.cleared ?? 0}/${survival?.wavesTotal ?? mode.waves}',
                    ),
                  _row('Log events', '${match.log.length}'),
                  _row(
                    'Allies standing',
                    '${match.player.where((c) => c.isAlive).length}',
                  ),
                  _row(
                    'Foes standing',
                    '${match.enemy.where((c) => c.isAlive).length}',
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (waveContinue)
              FilledButton(
                onPressed: onContinueSurvival,
                child: Text(
                  'NEXT WAVE (${survival!.wave}/${survival.wavesTotal})',
                ),
              )
            else
              FilledButton(
                onPressed: onRetry,
                child: Text(isSurvival ? 'RETRY SURVIVAL' : 'RETRY CLASH'),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                ref.read(matchProvider.notifier).clearSurvivalCarry();
                ref.read(matchProvider.notifier).clear();
                onReturnHome();
              },
              child: const Text('RETURN HOME'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            k,
            style: GoogleFonts.plusJakartaSans(
              color: AetheriumColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            v,
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
