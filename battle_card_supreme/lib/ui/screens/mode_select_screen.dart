import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/game_controllers.dart';
import '../../state/meta_controller.dart';
import '../../state/session_controller.dart';
import '../../theme/aetherium_theme.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({
    super.key,
    required this.onSelectClassic,
    required this.onSelectOnline,
    required this.onSelectSurvival,
    required this.onSelectPvp,
    required this.onNeedLogin,
    required this.onBack,
  });

  final VoidCallback onSelectClassic;
  final VoidCallback onSelectOnline;
  final VoidCallback onSelectSurvival;
  final VoidCallback onSelectPvp;
  final VoidCallback onNeedLogin;
  final VoidCallback onBack;

  IconData _iconFor(GameModeId id) {
    return switch (id) {
      GameModeId.onlineClash => Icons.cloud,
      GameModeId.survivalChallenge => Icons.trending_up,
      GameModeId.pvpClash => Icons.people_alt,
      GameModeId.bossRaidLocked || GameModeId.draftLocked => Icons.lock,
      GameModeId.classicClash => Icons.sports_martial_arts,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final meta = ref.watch(metaProvider).value ?? ServerMeta.offline;

    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text('BATTLE MODES'),
        actions: [
          TextButton(
            onPressed: session?.isAuthenticated == true
                ? () async {
                    await ref.read(sessionProvider.notifier).logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out.')),
                      );
                    }
                  }
                : onNeedLogin,
            child: Text(
              session?.isAuthenticated == true ? 'LOGOUT' : 'LOGIN',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            session?.isAuthenticated == true
                ? 'Signed in as ${session?.userName ?? session?.userEmail}'
                : 'Offline modes work now. Online clash needs a commander account.',
            style: GoogleFonts.plusJakartaSans(
              color: AetheriumColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ...kGameModes.map((mode) {
            final flagEnabled = switch (mode.id) {
              GameModeId.onlineClash => meta.flag('online_clash', fallback: true),
              GameModeId.survivalChallenge =>
                meta.flag('survival_challenge', fallback: true),
              GameModeId.pvpClash => meta.flag('pvp', fallback: true),
              _ => true,
            };
            final available = mode.available && flagEnabled;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (!available) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            flagEnabled
                                ? '${mode.title} is locked in this build.'
                                : '${mode.title} is disabled by server flag.',
                          ),
                        ),
                      );
                      return;
                    }
                    ref.read(activeModeProvider.notifier).setMode(mode.rules);
                    switch (mode.id) {
                      case GameModeId.classicClash:
                        onSelectClassic();
                      case GameModeId.onlineClash:
                        if (session?.isAuthenticated != true) {
                          onNeedLogin();
                          return;
                        }
                        onSelectOnline();
                      case GameModeId.survivalChallenge:
                        onSelectSurvival();
                      case GameModeId.pvpClash:
                        if (session?.isAuthenticated != true) {
                          onNeedLogin();
                          return;
                        }
                        onSelectPvp();
                      case GameModeId.bossRaidLocked:
                      case GameModeId.draftLocked:
                        break;
                    }
                  },
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AetheriumColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: available
                            ? AetheriumColors.primary.withValues(alpha: 0.45)
                            : AetheriumColors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: available
                                ? AetheriumColors.inversePrimary
                                : AetheriumColors.surfaceHigh,
                          ),
                          child: Icon(
                            available ? _iconFor(mode.id) : Icons.lock,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode.title.toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.04,
                                  color: available
                                      ? AetheriumColors.primary
                                      : AetheriumColors.outline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mode.subtitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AetheriumColors.onSurfaceVariant,
                                ),
                              ),
                              if (available) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Rules v${mode.rules.ruleVersion} · '
                                  '${mode.rules.teamSize}v${mode.rules.teamSize} · '
                                  '${mode.rules.maxRounds} rounds'
                                  '${mode.rules.waves > 1 ? ' · ${mode.rules.waves} waves' : ''}',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    color: AetheriumColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: available
                              ? AetheriumColors.secondary
                              : AetheriumColors.outlineVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
