import 'package:battle_card_supreme/domain/data/roster_seed.dart';
import 'package:battle_card_supreme/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foundation roster has exactly 50 cards', () {
    expect(kSeedRoster.length, 50);
  });

  test('rarity pyramid matches mandate', () {
    final counts = rosterRarityCounts();
    expect(counts[Rarity.common], 12);
    expect(counts[Rarity.uncommon], 10);
    expect(counts[Rarity.rare], 8);
    expect(counts[Rarity.superRare], 6);
    expect(counts[Rarity.epic], 5);
    expect(counts[Rarity.legendary], 4);
    expect(counts[Rarity.mythic], 3);
    expect(counts[Rarity.supreme], 2);
  });

  test('ids are unique', () {
    final ids = kSeedRoster.map((c) => c.id).toSet();
    expect(ids.length, kSeedRoster.length);
  });

  test('every primary role appears at least twice in common to rare', () {
    final early = kSeedRoster.where(
      (c) =>
          c.rarity == Rarity.common ||
          c.rarity == Rarity.uncommon ||
          c.rarity == Rarity.rare,
    );
    for (final role in CardRole.values) {
      final n = early.where((c) => c.role == role).length;
      expect(n, greaterThanOrEqualTo(2), reason: role.name);
    }
  });
}
