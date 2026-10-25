import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/data/roster_seed.dart';
import '../../state/collection_controller.dart';
import '../../state/game_controllers.dart';
import '../../state/meta_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/ranking_controller.dart';
import '../../state/session_controller.dart';
import '../../theme/aetherium_theme.dart';
import '../widgets/card_art.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onEnterCombat,
    required this.onOpenCard,
    required this.onOpenCollection,
    this.onOpenRanking,
  });

  final VoidCallback onEnterCombat;
  final void Function(String cardId) onOpenCard;
  final VoidCallback onOpenCollection;
  final VoidCallback? onOpenRanking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider);
    final collection = ref.watch(collectionProvider).value;
    final teamError = teamAsync.whenOrNull(
      data: (ids) => ref.read(teamProvider.notifier).validate(ids),
    );
    final teamIds = teamAsync.value ?? const <String>[];
    final session = ref.watch(sessionProvider).value;
    final progress = ref.watch(progressProvider).value;
    final meta = ref.watch(metaProvider).value;
    final ranking = ref.watch(rankingProvider).value;
    final rankingOn = meta?.flag('ranking', fallback: true) ?? true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AetheriumColors.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign, color: AetheriumColors.secondary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'EVENT  ·  Foundation roster live: ${kSeedRoster.length} relics.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AetheriumColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (session?.isAuthenticated == true && progress != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AetheriumColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AetheriumColors.secondary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CMD LV ${progress.level}',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          color: AetheriumColors.primary,
                        ),
                      ),
                      Text(
                        'XP ${progress.xp}/${progress.xpToNext}  ·  EN ${progress.energy}/${progress.energyMax}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AetheriumColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${progress.riftMarks} M  ·  ${progress.aether} Æ',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    color: AetheriumColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (rankingOn && onOpenRanking != null) ...[
          const SizedBox(height: 10),
          Material(
            color: AetheriumColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onOpenRanking,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AetheriumColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined,
                        color: AetheriumColors.secondary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FOUNDATION RANKING',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              letterSpacing: 0.06,
                              fontWeight: FontWeight.w700,
                              color: AetheriumColors.secondary,
                            ),
                          ),
                          Text(
                            ranking?.me != null
                                ? 'Elo ${ranking!.me!.rating}  ·  Rank ${ranking.me!.rank ?? '—'}'
                                : 'Open leaderboard',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              color: AetheriumColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AetheriumColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'YOUR SQUAD',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.06,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: Row(
            children: List.generate(kBattleTeamSize, (i) {
              final id = i < teamIds.length ? teamIds[i] : null;
              final card = id != null ? cardById(id) : null;
              final owned = id != null
                  ? collection?.byId(id)
                  : null;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == kBattleTeamSize - 1 ? 0 : 8),
                  child: Material(
                    color: AetheriumColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: card == null
                          ? onOpenCollection
                          : () => onOpenCard(card.id),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AetheriumColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: card == null
                            ? Center(
                                child: Text(
                                  'EMPTY',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    color: AetheriumColors.outline,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(9),
                                      ),
                                      child: CardArt(
                                        card: card,
                                        borderRadius: 0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                                    child: Column(
                                      children: [
                                        Text(
                                          card.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'LV ${owned?.level ?? 1}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: AetheriumColors.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AetheriumColors.primaryContainer.withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
          child: FilledButton(
            onPressed: onEnterCombat,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              backgroundColor: AetheriumColors.surfaceLowest,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [
                        AetheriumColors.primaryContainer,
                        AetheriumColors.inversePrimary,
                      ],
                    ),
                  ),
                  child: const Icon(Icons.sports_martial_arts, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RANKED SEASON  ·  OFFLINE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          letterSpacing: 0.08,
                          color: AetheriumColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'ENTER COMBAT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AetheriumColors.primary,
                        ),
                      ),
                      Text(
                        teamError ?? 'Open mode select  ·  Classic Clash ready',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: teamError == null
                              ? AetheriumColors.onSurfaceVariant
                              : AetheriumColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'COLLECTION PROGRESS',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.06,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          collection == null
              ? 'Sign in to track unlocked relics.'
              : '${collection.countOwned}/${collection.countTotal} unlocked. Earn Marks from victories, buy keys, open chests.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.4,
            color: AetheriumColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onOpenCollection,
          child: const Text('OPEN VAULT'),
        ),
      ],
    );
  }
}
