import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'domain/combat/combat_models.dart';
import 'state/game_controllers.dart';
import 'state/meta_controller.dart';
import 'theme/aetherium_theme.dart';
import 'ui/screens/battle_prep_screen.dart';
import 'ui/screens/battle_screen.dart';
import 'ui/screens/card_detail_screen.dart';
import 'ui/screens/collection_screen.dart';
import 'ui/screens/exchange_screen.dart';
import 'ui/screens/force_upgrade_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/leaderboard_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/mode_select_screen.dart';
import 'ui/screens/online_battle_screen.dart';
import 'ui/screens/online_result_screen.dart';
import 'ui/screens/pvp_queue_screen.dart';
import 'ui/screens/result_screen.dart';
import 'ui/screens/team_screen.dart';
import 'ui/widgets/card_art.dart';

class BattleCardSupremeApp extends StatelessWidget {
  const BattleCardSupremeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Battle Card Supreme',
        debugShowCheckedModeBanner: false,
        theme: buildAetheriumTheme(),
        home: const BootGate(),
      ),
    );
  }
}

class BootGate extends ConsumerWidget {
  const BootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metaAsync = ref.watch(metaProvider);
    return metaAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandLogo(height: 140),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
      error: (_, __) => const RootShell(),
      data: (meta) {
        if (meta.forceUpgrade) {
          return ForceUpgradeScreen(
            currentVersion: kAppVersion,
            minVersion: meta.minAppVersion,
          );
        }
        return const RootShell();
      },
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;
  final _nav = GlobalKey<NavigatorState>();

  void _goHome() {
    _nav.currentState?.popUntil((r) => r.isFirst);
    setState(() => _tab = 0);
  }

  void _openCard(String id) {
    _nav.currentState?.push(
      MaterialPageRoute(builder: (_) => CardDetailScreen(cardId: id)),
    );
  }

  void _openLogin({VoidCallback? thenOnline}) {
    _nav.currentState?.push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onSuccess: () {
            _nav.currentState?.pop();
            thenOnline?.call();
          },
        ),
      ),
    );
  }

  void _openOnlineBattle({int? matchId}) {
    _nav.currentState?.push(
      MaterialPageRoute(
        builder: (_) => OnlineBattleScreen(
          existingMatchId: matchId,
          onFinished: () {
            _nav.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (_) => OnlineResultScreen(onReturnHome: _goHome),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPvpQueue() {
    _nav.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PvpQueueScreen(
          onBack: () => _nav.currentState?.pop(),
          onMatchReady: (matchId) {
            _nav.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (_) => OnlineBattleScreen(
                  existingMatchId: matchId,
                  onFinished: () {
                    _nav.currentState?.pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            OnlineResultScreen(onReturnHome: _goHome),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openRanking() {
    _nav.currentState?.push(
      MaterialPageRoute(
        builder: (_) => LeaderboardScreen(
          onBack: () => _nav.currentState?.pop(),
        ),
      ),
    );
  }

  void _openPrep({required VoidCallback onFight}) {
    _nav.currentState?.push(
      MaterialPageRoute(
        builder: (_) => BattlePrepScreen(
          onBack: () => _nav.currentState?.pop(),
          onEditSquad: () {
            _nav.currentState?.popUntil((r) => r.isFirst);
            setState(() => _tab = 2);
          },
          onFight: onFight,
        ),
      ),
    );
  }

  void _openModeSelect() {
    _nav.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ModeSelectScreen(
          onBack: () => _nav.currentState?.pop(),
          onNeedLogin: () => _openLogin(thenOnline: _openOnlineBattle),
          onSelectOnline: _openOnlineBattle,
          onSelectPvp: _openPvpQueue,
          onSelectClassic: () => _openPrep(onFight: _openOfflineBattle),
          onSelectSurvival: () => _openPrep(onFight: _openSurvivalBattle),
        ),
      ),
    );
  }

  void _handleOfflineFinished() {
    final container = ProviderScope.containerOf(_nav.currentContext!);
    final match = container.read(matchProvider);
    final mode = container.read(activeModeProvider);
    final isSurvival = mode.code == 'survival_challenge';

    if (isSurvival && match != null) {
      if (match.outcome == MatchOutcome.victoryPlayer) {
        container.read(matchProvider.notifier).advanceSurvivalAfterVictory();
      } else {
        container.read(matchProvider.notifier).noteSurvivalFailure();
      }
    }

    _nav.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          onReturnHome: _goHome,
          onContinueSurvival: () {
            final err =
                container.read(matchProvider.notifier).startSurvivalWave();
            if (err != null) {
              ScaffoldMessenger.of(_nav.currentContext!).showSnackBar(
                SnackBar(content: Text(err)),
              );
              return;
            }
            _nav.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (_) => BattleScreen(onFinished: _handleOfflineFinished),
              ),
            );
          },
          onRetry: () {
            final matchCtrl = container.read(matchProvider.notifier);
            final String? err;
            if (isSurvival) {
              matchCtrl.clearSurvivalCarry();
              container.read(survivalRunProvider.notifier).begin(mode);
              err = matchCtrl.startSurvivalWave();
            } else {
              err = matchCtrl.startVsAi(mode: mode);
            }
            if (err != null) {
              ScaffoldMessenger.of(_nav.currentContext!).showSnackBar(
                SnackBar(content: Text(err)),
              );
              return;
            }
            _nav.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (_) => BattleScreen(onFinished: _handleOfflineFinished),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openOfflineBattle() {
    _nav.currentState?.push(
      MaterialPageRoute(
        builder: (_) => BattleScreen(onFinished: _handleOfflineFinished),
      ),
    );
  }

  void _openSurvivalBattle() {
    _nav.currentState?.push(
      MaterialPageRoute(
        builder: (_) => BattleScreen(onFinished: _handleOfflineFinished),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _nav,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AetheriumColors.surface,
            appBar: AppBar(
              titleSpacing: 12,
              title: Row(
                children: [
                  const BrandLogo(height: 40, square: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aetherium Rift',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AetheriumColors.primary,
                          ),
                        ),
                        Text(
                          'BATTLE CARD SUPREME',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            letterSpacing: 0.08,
                            color: AetheriumColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: IndexedStack(
              index: _tab,
              children: [
                HomeScreen(
                  onEnterCombat: _openModeSelect,
                  onOpenCard: _openCard,
                  onOpenCollection: () => setState(() => _tab = 1),
                  onOpenRanking: _openRanking,
                ),
                CollectionScreen(onOpenCard: _openCard),
                TeamScreen(
                  onOpenCard: _openCard,
                  onStartBattle: _openModeSelect,
                ),
                ExchangeScreen(onNeedLogin: () => _openLogin()),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.style_outlined),
                  selectedIcon: Icon(Icons.style),
                  label: 'Vault',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: 'Squad',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: 'Exchange',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
