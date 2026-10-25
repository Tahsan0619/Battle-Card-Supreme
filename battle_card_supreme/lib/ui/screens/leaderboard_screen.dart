import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/ranking_controller.dart';
import '../../theme/aetherium_theme.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rankingProvider);

    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(
          'RANKING',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(rankingProvider.notifier).refresh(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Ranking unreachable.',
            style: GoogleFonts.plusJakartaSans(
              color: AetheriumColors.onSurfaceVariant,
            ),
          ),
        ),
        data: (snap) {
          if (snap == null) {
            return Center(
              child: Text(
                'Ranking is offline for this build.',
                style: GoogleFonts.plusJakartaSans(
                  color: AetheriumColors.onSurfaceVariant,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              Text(
                'SEASON  ·  ${snap.seasonCode.toUpperCase()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  letterSpacing: 0.08,
                  fontWeight: FontWeight.w700,
                  color: AetheriumColors.secondary,
                ),
              ),
              if (snap.me != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AetheriumColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AetheriumColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR STANDING',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                letterSpacing: 0.06,
                                color: AetheriumColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Rank ${snap.me!.rank ?? '—'}  ·  ${snap.me!.rating} Elo',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w700,
                                color: AetheriumColors.primary,
                              ),
                            ),
                            Text(
                              'W ${snap.me!.wins}  L ${snap.me!.losses}  D ${snap.me!.draws}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AetheriumColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'LEADERBOARD',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.06,
                ),
              ),
              const SizedBox(height: 8),
              if (snap.entries.isEmpty)
                Text(
                  'No ranked commanders yet. Win a PvP duel to place.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AetheriumColors.onSurfaceVariant,
                  ),
                )
              else
                ...snap.entries.map((e) {
                  final isMe = snap.me?.userId == e.userId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AetheriumColors.surfaceHigh
                          : AetheriumColors.surfaceLow,
                      borderRadius: BorderRadius.circular(10),
                      border: isMe
                          ? Border.all(
                              color: AetheriumColors.primary
                                  .withValues(alpha: 0.4),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '#${e.rank ?? '—'}',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              color: AetheriumColors.secondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.displayName ?? 'Commander ${e.userId}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight:
                                  isMe ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${e.rating}',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            color: AetheriumColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
