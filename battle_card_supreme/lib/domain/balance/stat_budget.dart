import '../models/enums.dart';

/// Base budget points for Common rarity. All other rarities scale by percent.
const int kCommonBaseBudget = 1000;

class StatBlock {
  const StatBlock({
    required this.hp,
    required this.atk,
    required this.def,
    required this.spd,
    required this.en,
  });

  final int hp;
  final int atk;
  final int def;
  final int spd;
  final int en;

  int get combatSum => hp + atk + def + spd + en;

  StatBlock copyWith({int? hp, int? atk, int? def, int? spd, int? en}) {
    return StatBlock(
      hp: hp ?? this.hp,
      atk: atk ?? this.atk,
      def: def ?? this.def,
      spd: spd ?? this.spd,
      en: en ?? this.en,
    );
  }
}

/// Role weights must sum to 100. Used to divide the rarity budget.
Map<String, int> roleWeights(CardRole role) {
  return switch (role) {
    CardRole.tank => {'hp': 40, 'atk': 10, 'def': 30, 'spd': 10, 'en': 10},
    CardRole.attacker => {'hp': 20, 'atk': 40, 'def': 15, 'spd': 15, 'en': 10},
    CardRole.support => {'hp': 30, 'atk': 10, 'def': 20, 'spd': 15, 'en': 25},
    CardRole.assassin => {'hp': 15, 'atk': 40, 'def': 10, 'spd': 25, 'en': 10},
    CardRole.mage => {'hp': 18, 'atk': 35, 'def': 12, 'spd': 15, 'en': 20},
    CardRole.strategist => {'hp': 25, 'atk': 20, 'def': 20, 'spd': 15, 'en': 20},
    CardRole.skirmisher => {'hp': 18, 'atk': 25, 'def': 12, 'spd': 35, 'en': 10},
    CardRole.summoner => {'hp': 22, 'atk': 20, 'def': 18, 'spd': 15, 'en': 25},
  };
}

int budgetFor(Rarity rarity) {
  return (kCommonBaseBudget * rarity.budgetPercent) ~/ 100;
}

/// Divides rarity budget across stats by role. Remainder goes to HP.
/// Soft caps prevent a single stat from eating the whole pie.
StatBlock divideStats({
  required Rarity rarity,
  required CardRole role,
  Map<String, int>? identityBias,
}) {
  final total = budgetFor(rarity);
  final weights = Map<String, int>.from(roleWeights(role));
  if (identityBias != null) {
    for (final e in identityBias.entries) {
      weights[e.key] = (weights[e.key] ?? 0) + e.value;
    }
  }
  final weightSum = weights.values.fold<int>(0, (a, b) => a + b);
  if (weightSum <= 0) {
    throw ArgumentError('Role weights must sum to a positive value');
  }

  int alloc(String key) => (total * (weights[key] ?? 0)) ~/ weightSum;

  var hp = alloc('hp').clamp(50, total);
  var atk = alloc('atk').clamp(10, total ~/ 2);
  var def = alloc('def').clamp(10, total ~/ 2);
  var spd = alloc('spd').clamp(5, total ~/ 3);
  var en = alloc('en').clamp(5, total ~/ 3);

  var used = hp + atk + def + spd + en;
  if (used < total) {
    hp += total - used;
  } else if (used > total) {
    final overflow = used - total;
    hp = (hp - overflow).clamp(50, total);
  }

  return StatBlock(hp: hp, atk: atk, def: def, spd: spd, en: en);
}

bool withinBudget(StatBlock stats, Rarity rarity, {int tolerance = 0}) {
  final maxAllowed = budgetFor(rarity) + tolerance;
  return stats.combatSum <= maxAllowed;
}
