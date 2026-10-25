import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_client.dart';
import '../domain/data/roster_seed.dart';
import '../domain/models/card_definition.dart';
import 'session_controller.dart';

class OwnedCardState {
  const OwnedCardState({
    required this.card,
    required this.owned,
    required this.level,
    required this.copies,
    this.copiesToNext,
    this.playerCardId,
  });

  final CardDefinition card;
  final bool owned;
  final int level;
  final int copies;
  final int? copiesToNext;
  final int? playerCardId;
}

class CollectionSnapshot {
  const CollectionSnapshot({
    required this.entries,
    required this.countOwned,
    required this.countTotal,
    required this.maxCardLevel,
  });

  final List<OwnedCardState> entries;
  final int countOwned;
  final int countTotal;
  final int maxCardLevel;

  Set<String> get ownedIds =>
      entries.where((e) => e.owned).map((e) => e.card.id).toSet();

  OwnedCardState? byId(String id) {
    for (final e in entries) {
      if (e.card.id == id) return e;
    }
    return null;
  }
}

class CollectionController extends AsyncNotifier<CollectionSnapshot> {
  @override
  Future<CollectionSnapshot> build() async {
    final session = await ref.watch(sessionProvider.future);
    if (!session.isAuthenticated) {
      // Offline / logged out: nothing owned until exchange progression.
      return CollectionSnapshot(
        entries: kSeedRoster
            .map(
              (c) => OwnedCardState(
                card: c,
                owned: false,
                level: 0,
                copies: 0,
              ),
            )
            .toList(),
        countOwned: 0,
        countTotal: kSeedRoster.length,
        maxCardLevel: 10,
      );
    }

    try {
      final body =
          await ref.read(sessionProvider.notifier).client.collection();
      return _fromApi(body);
    } on ApiException {
      return CollectionSnapshot(
        entries: kSeedRoster
            .map(
              (c) => OwnedCardState(
                card: c,
                owned: false,
                level: 0,
                copies: 0,
              ),
            )
            .toList(),
        countOwned: 0,
        countTotal: kSeedRoster.length,
        maxCardLevel: 10,
      );
    }
  }

  CollectionSnapshot _fromApi(Map<String, dynamic> body) {
    final raw = (body['collection'] as List?) ?? const [];
    final byCode = <String, OwnedCardState>{};
    for (final row in raw) {
      if (row is! Map) continue;
      final cardJson = (row['card'] as Map?)?.cast<String, dynamic>();
      final code = cardJson?['code'] as String? ?? cardJson?['id'] as String?;
      final local = code != null ? cardById(code) : null;
      if (local == null) continue;
      byCode[local.id] = OwnedCardState(
        card: local,
        owned: row['owned'] == true,
        level: row['level'] as int? ?? 0,
        copies: row['copies'] as int? ?? 0,
        copiesToNext: row['copies_to_next'] as int?,
        playerCardId: row['player_card_id'] as int?,
      );
    }
    final entries = kSeedRoster.map((c) {
      return byCode[c.id] ??
          OwnedCardState(card: c, owned: false, level: 0, copies: 0);
    }).toList();
    return CollectionSnapshot(
      entries: entries,
      countOwned: body['count_owned'] as int? ??
          entries.where((e) => e.owned).length,
      countTotal: body['count_total'] as int? ?? kSeedRoster.length,
      maxCardLevel: body['max_card_level'] as int? ?? 10,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }

  Future<String?> levelUp(String cardId) async {
    try {
      await ref.read(sessionProvider.notifier).client.levelUpCard(cardId);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Level-up failed.';
    }
  }
}

final collectionProvider =
    AsyncNotifierProvider<CollectionController, CollectionSnapshot>(
  CollectionController.new,
);
