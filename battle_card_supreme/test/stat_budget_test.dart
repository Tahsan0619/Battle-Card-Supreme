import 'package:battle_card_supreme/domain/balance/stat_budget.dart';
import 'package:battle_card_supreme/domain/data/roster_seed.dart';
import 'package:battle_card_supreme/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('role weights sum to 100', () {
    for (final role in CardRole.values) {
      final sum = roleWeights(role).values.fold<int>(0, (a, b) => a + b);
      expect(sum, 100, reason: role.name);
    }
  });

  test('divided stats stay within rarity budget', () {
    for (final rarity in Rarity.values) {
      for (final role in CardRole.values) {
        final stats = divideStats(rarity: rarity, role: role);
        expect(
          withinBudget(stats, rarity),
          isTrue,
          reason: '${rarity.name} ${role.name} sum=${stats.combatSum}',
        );
      }
    }
  });

  test('seed roster complies with budgets', () {
    for (final card in kSeedRoster) {
      expect(
        withinBudget(card.stats, card.rarity, tolerance: 5),
        isTrue,
        reason: '${card.id} sum=${card.stats.combatSum}',
      );
    }
  });

  test('seed covers all eight rarities', () {
    final rarities = kSeedRoster.map((c) => c.rarity).toSet();
    expect(rarities, containsAll(Rarity.values));
  });
}
