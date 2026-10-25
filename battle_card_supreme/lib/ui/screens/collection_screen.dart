import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/enums.dart';
import '../../state/collection_controller.dart';
import '../../state/game_controllers.dart';
import '../../theme/aetherium_theme.dart';
import '../widgets/card_grid_cell.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key, required this.onOpenCard});

  final void Function(String cardId) onOpenCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionProvider);
    final filter = ref.watch(selectedRarityFilterProvider);

    return collectionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Vault unreachable.')),
      data: (snap) {
        final filtered = filter == null
            ? snap.entries
            : snap.entries
                .where((e) => e.card.rarity.name == filter)
                .toList();

        return Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _FilterChip(
                    label: 'ALL',
                    selected: filter == null,
                    onTap: () => ref
                        .read(selectedRarityFilterProvider.notifier)
                        .setFilter(null),
                  ),
                  ...Rarity.values.map(
                    (r) => _FilterChip(
                      label: r.code,
                      selected: filter == r.name,
                      onTap: () => ref
                          .read(selectedRarityFilterProvider.notifier)
                          .setFilter(r.name),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${snap.countOwned}/${snap.countTotal} unlocked  ·  open chests in Exchange',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AetheriumColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.68,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final entry = filtered[i];
                  return CardGridCell(
                    card: entry.card,
                    owned: entry.owned,
                    level: entry.level,
                    onTap: () => onOpenCard(entry.card.id),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AetheriumColors.primary.withValues(alpha: 0.2)
                : AetheriumColors.surfaceLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AetheriumColors.primary
                  : AetheriumColors.outlineVariant,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AetheriumColors.onSurface
                    : AetheriumColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
