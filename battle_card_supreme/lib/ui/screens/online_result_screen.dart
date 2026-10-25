import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/api/api_client.dart';
import '../../state/game_controllers.dart';
import '../../state/progress_controller.dart';
import '../../theme/aetherium_theme.dart';

class OnlineResultScreen extends ConsumerStatefulWidget {
  const OnlineResultScreen({super.key, required this.onReturnHome});

  final VoidCallback onReturnHome;

  @override
  ConsumerState<OnlineResultScreen> createState() => _OnlineResultScreenState();
}

class _OnlineResultScreenState extends ConsumerState<OnlineResultScreen> {
  bool _claiming = false;
  String? _claimMessage;
  bool _claimed = false;

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(onlineResultProvider);
    final outcome = match?['outcome'] as String? ??
        (match?['state'] as Map?)?['outcome'] as String? ??
        'unknown';
    final matchId = match?['id'] as int?;
    final claimable = match?['rewards_claimable'] == true && !_claimed;
    final already = match?['rewards_claimed'] == true || _claimed;

    final (title, color) = switch (outcome) {
      'victory_player' => ('VICTORY', AetheriumColors.success),
      'victory_enemy' => ('DEFEAT', AetheriumColors.error),
      'draw' => ('DRAW', AetheriumColors.tertiary),
      'forfeit_player' => ('FORFEIT', AetheriumColors.outline),
      _ => ('CLASH RESOLVED', AetheriumColors.primary),
    };

    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      appBar: AppBar(title: const Text('ONLINE RESULT')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Server-authored outcome. Balance freeze v${match?['balance_version'] ?? 1}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AetheriumColors.onSurfaceVariant,
              ),
            ),
            if (_claimMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _claimMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AetheriumColors.secondary,
                ),
              ),
            ],
            const Spacer(),
            if (claimable && matchId != null)
              FilledButton(
                onPressed: _claiming
                    ? null
                    : () async {
                        setState(() => _claiming = true);
                        try {
                          final body = await ref
                              .read(progressProvider.notifier)
                              .claimVictory(
                                matchId: matchId,
                                clientClaimId:
                                    'claim-$matchId-${DateTime.now().microsecondsSinceEpoch}',
                              );
                          final claim =
                              (body?['claim'] as Map?)?.cast<String, dynamic>();
                          final xp = claim?['xp_granted'];
                          final aether = claim?['aether_granted'];
                          setState(() {
                            _claimed = true;
                            _claimMessage =
                                'Claimed +$xp XP and +$aether Aether.';
                          });
                        } on ApiException catch (e) {
                          setState(() => _claimMessage = e.message);
                        } finally {
                          if (mounted) setState(() => _claiming = false);
                        }
                      },
                child: Text(_claiming ? 'CLAIMING…' : 'CLAIM VICTORY REWARDS'),
              )
            else if (already && outcome == 'victory_player')
              Text(
                'Victory rewards already claimed.',
                style: GoogleFonts.plusJakartaSans(
                  color: AetheriumColors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: widget.onReturnHome,
              child: const Text('RETURN HOME'),
            ),
          ],
        ),
      ),
    );
  }
}
