import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/api/api_client.dart';
import '../../domain/data/roster_seed.dart';
import '../../state/collection_controller.dart';
import '../../state/game_controllers.dart';
import '../../state/session_controller.dart';
import '../../theme/aetherium_theme.dart';
import '../widgets/card_tile.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({
    super.key,
    required this.onOpenCard,
    required this.onStartBattle,
  });

  final void Function(String cardId) onOpenCard;
  final VoidCallback onStartBattle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider);
    final collection = ref.watch(collectionProvider).value;
    final ownedCards = (collection?.entries ?? const [])
        .where((e) => e.owned)
        .map((e) => e.card)
        .toList();

    return teamAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load squad: $e')),
      data: (ids) {
        final error = ref.read(teamProvider.notifier).validate(ids);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'TACTICAL SQUAD  (${ids.length}/$kBattleTeamSize)',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: ids.isEmpty
                        ? null
                        : () => ref.read(teamProvider.notifier).clear(),
                    child: const Text('CLEAR'),
                  ),
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    error,
                    style: GoogleFonts.plusJakartaSans(
                      color: AetheriumColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: 96,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: kBattleTeamSize,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i >= ids.length) {
                    return Container(
                      width: 96,
                      decoration: BoxDecoration(
                        color: AetheriumColors.surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AetheriumColors.outlineVariant,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'EMPTY',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          color: AetheriumColors.outline,
                        ),
                      ),
                    );
                  }
                  final card = cardById(ids[i])!;
                  return SizedBox(
                    width: 220,
                    child: CardTile(
                      card: card,
                      compact: true,
                      onTap: () => onOpenCard(card.id),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () =>
                            ref.read(teamProvider.notifier).remove(card.id),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: error != null ? null : onStartBattle,
                      child: const Text('PREPARE CLASH'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: error != null
                          ? null
                          : () async {
                              final session = ref.read(sessionProvider).value;
                              if (session?.isAuthenticated != true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Login first from Battle Modes.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              try {
                                await ref
                                    .read(sessionProvider.notifier)
                                    .client
                                    .syncTeam(cardCodes: ids);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Squad synced to server Main Squad.',
                                      ),
                                    ),
                                  );
                                }
                              } on ApiException catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message)),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Sync failed. Is the API running?',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      child: const Text('SYNC ONLINE'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'OWNED RELICS  ·  tap to add  ·  unlock more in Exchange',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AetheriumColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ownedCards.isEmpty
                  ? Center(
                      child: Text(
                        'No owned relics yet.\nOpen chests in Exchange.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: AetheriumColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: ownedCards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final card = ownedCards[i];
                        final selected = ids.contains(card.id);
                        final entry = collection?.byId(card.id);
                        return CardTile(
                          card: card,
                          compact: true,
                          selected: selected,
                          trailing: Text(
                            'LV ${entry?.level ?? 1}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AetheriumColors.secondary,
                            ),
                          ),
                          onTap: () async {
                            final n = ref.read(teamProvider.notifier);
                            if (selected) {
                              await n.remove(card.id);
                              return;
                            }
                            final ok = await n.add(card.id);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ids.length >= kBattleTeamSize
                                        ? 'Squad is full.'
                                        : 'Could not add card.',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
