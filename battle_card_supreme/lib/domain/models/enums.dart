enum Rarity {
  common,
  uncommon,
  rare,
  superRare,
  epic,
  legendary,
  mythic,
  supreme,
}

extension RarityX on Rarity {
  String get code => switch (this) {
        Rarity.common => 'C',
        Rarity.uncommon => 'UC',
        Rarity.rare => 'R',
        Rarity.superRare => 'SR',
        Rarity.epic => 'E',
        Rarity.legendary => 'L',
        Rarity.mythic => 'M',
        Rarity.supreme => 'S',
      };

  String get label => switch (this) {
        Rarity.common => 'Common',
        Rarity.uncommon => 'Uncommon',
        Rarity.rare => 'Rare',
        Rarity.superRare => 'Super Rare',
        Rarity.epic => 'Epic',
        Rarity.legendary => 'Legendary',
        Rarity.mythic => 'Mythic',
        Rarity.supreme => 'Supreme',
      };

  /// Relative budget percent vs Common = 100.
  int get budgetPercent => switch (this) {
        Rarity.common => 100,
        Rarity.uncommon => 108,
        Rarity.rare => 118,
        Rarity.superRare => 128,
        Rarity.epic => 140,
        Rarity.legendary => 155,
        Rarity.mythic => 170,
        Rarity.supreme => 185,
      };

  int get sortWeight => index;
}

enum CardRole {
  tank,
  attacker,
  support,
  assassin,
  mage,
  strategist,
  skirmisher,
  summoner,
}

extension CardRoleX on CardRole {
  String get label => switch (this) {
        CardRole.tank => 'Tank',
        CardRole.attacker => 'Attacker',
        CardRole.support => 'Support',
        CardRole.assassin => 'Assassin',
        CardRole.mage => 'Mage',
        CardRole.strategist => 'Strategist',
        CardRole.skirmisher => 'Skirmisher',
        CardRole.summoner => 'Summoner',
      };
}

enum Faction {
  aetherVanguard,
  voidSyndicate,
  stormCourt,
  forgeCovenant,
  eclipseOrder,
  riftborn,
}

extension FactionX on Faction {
  String get label => switch (this) {
        Faction.aetherVanguard => 'Aether Vanguard',
        Faction.voidSyndicate => 'Void Syndicate',
        Faction.stormCourt => 'Storm Court',
        Faction.forgeCovenant => 'Forge Covenant',
        Faction.eclipseOrder => 'Eclipse Order',
        Faction.riftborn => 'Riftborn',
      };
}
