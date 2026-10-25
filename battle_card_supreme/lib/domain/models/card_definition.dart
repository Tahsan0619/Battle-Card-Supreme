import '../balance/stat_budget.dart';
import 'enums.dart';

class AbilityDefinition {
  const AbilityDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.enCost,
    required this.cooldownTurns,
    required this.multiplierPercent,
    this.healPercent = 0,
    this.shieldPercent = 0,
    this.isAoe = false,
  });

  final String id;
  final String name;
  final String description;
  final int enCost;
  final int cooldownTurns;
  final int multiplierPercent;
  final int healPercent;
  final int shieldPercent;
  final bool isAoe;
}

class CardDefinition {
  const CardDefinition({
    required this.id,
    required this.name,
    required this.pitch,
    required this.lore,
    required this.rarity,
    required this.role,
    required this.faction,
    required this.stats,
    required this.passiveName,
    required this.passiveDescription,
    required this.active,
    this.epithet = '',
    this.origin = '',
    this.quote = '',
    this.story = '',
    this.synergyTags = const [],
    this.artSeed = 0,
    this.balanceVersion = 1,
    this.cardVersion = 1,
  });

  final String id;
  final String name;
  final String pitch;
  final String lore;
  final String epithet;
  final String origin;
  final String quote;
  final String story;
  final Rarity rarity;
  final CardRole role;
  final Faction faction;
  final StatBlock stats;
  final String passiveName;
  final String passiveDescription;
  final AbilityDefinition active;
  final List<String> synergyTags;
  final int artSeed;
  final int balanceVersion;
  final int cardVersion;

  String get displayEpithet => epithet.isNotEmpty ? epithet : pitch;
  String get displayStory => story.isNotEmpty ? story : lore;
  String get displayQuote => quote;
  String get displayOrigin => origin;

  int get powerDisplay =>
      stats.hp + stats.atk * 2 + stats.def * 2 + stats.spd + stats.en;
}
