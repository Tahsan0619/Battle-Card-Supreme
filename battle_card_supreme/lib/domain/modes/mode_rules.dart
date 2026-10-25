/// Shared mode configuration mirrored from API `game_modes` / `mode_rule_versions`.
/// Offline play uses this local catalog; online can overlay GET /api/modes.
class ModeRules {
  const ModeRules({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.available,
    required this.ruleVersion,
    required this.teamSize,
    required this.maxRounds,
    required this.waves,
    required this.healBetweenWavesPercent,
    required this.ownershipRequired,
    required this.rankingEligible,
    required this.opponent,
    required this.channel,
  });

  final String code;
  final String title;
  final String subtitle;
  final bool available;
  final int ruleVersion;
  final int teamSize;
  final int maxRounds;
  final int waves;
  final int healBetweenWavesPercent;
  final bool ownershipRequired;
  final bool rankingEligible;
  final String opponent;
  final String channel;

  bool get isOfflineOnly => channel == 'offline';
  bool get isOnlineOnly => channel == 'online';

  factory ModeRules.fromJson(Map<String, dynamic> json) {
    final rules = (json['rules'] as Map?)?.cast<String, dynamic>() ?? const {};
    return ModeRules(
      code: json['code'] as String,
      title: json['title'] as String? ?? json['code'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      available: json['available'] as bool? ?? false,
      ruleVersion: json['rule_version'] as int? ?? 1,
      teamSize: rules['team_size'] as int? ?? 3,
      maxRounds: rules['max_rounds'] as int? ?? 30,
      waves: rules['waves'] as int? ?? 1,
      healBetweenWavesPercent:
          rules['heal_between_waves_percent'] as int? ?? 0,
      ownershipRequired: rules['ownership_required'] as bool? ?? true,
      rankingEligible: rules['ranking_eligible'] as bool? ?? false,
      opponent: rules['opponent'] as String? ?? 'ai',
      channel: rules['channel'] as String? ?? 'both',
    );
  }
}

const kClassicClash = ModeRules(
  code: 'classic_clash',
  title: 'Classic Card Clash',
  subtitle: 'Turn-based squad vs local AI. Offline ready.',
  available: true,
  ruleVersion: 1,
  teamSize: 3,
  maxRounds: 30,
  waves: 1,
  healBetweenWavesPercent: 0,
  ownershipRequired: true,
  rankingEligible: false,
  opponent: 'ai',
  channel: 'both',
);

const kOnlineClash = ModeRules(
  code: 'online_clash',
  title: 'Online Card Clash',
  subtitle: 'Server-authoritative combat. Requires login.',
  available: true,
  ruleVersion: 1,
  teamSize: 3,
  maxRounds: 30,
  waves: 1,
  healBetweenWavesPercent: 0,
  ownershipRequired: true,
  rankingEligible: false,
  opponent: 'ai',
  channel: 'online',
);

const kSurvivalChallenge = ModeRules(
  code: 'survival_challenge',
  title: 'Survival Challenge',
  subtitle: 'Three escalating waves. HP carries between fights.',
  available: true,
  ruleVersion: 1,
  teamSize: 3,
  maxRounds: 20,
  waves: 3,
  healBetweenWavesPercent: 25,
  ownershipRequired: true,
  rankingEligible: false,
  opponent: 'ai',
  channel: 'offline',
);

const kPvpClash = ModeRules(
  code: 'pvp_clash',
  title: 'PvP Card Clash',
  subtitle: 'Queue, accept window, then live duel vs another commander.',
  available: true,
  ruleVersion: 1,
  teamSize: 3,
  maxRounds: 30,
  waves: 1,
  healBetweenWavesPercent: 0,
  ownershipRequired: true,
  rankingEligible: false,
  opponent: 'human',
  channel: 'online',
);

const kBossRaidLocked = ModeRules(
  code: 'boss_raid',
  title: 'Boss Raid',
  subtitle: 'Phased AI boss. Coming later.',
  available: false,
  ruleVersion: 1,
  teamSize: 3,
  maxRounds: 40,
  waves: 1,
  healBetweenWavesPercent: 0,
  ownershipRequired: true,
  rankingEligible: false,
  opponent: 'boss',
  channel: 'both',
);

const kDraftLocked = ModeRules(
  code: 'draft_challenge',
  title: 'Draft Challenge',
  subtitle: 'Limited pool drafting. Locked for now.',
  available: false,
  ruleVersion: 1,
  teamSize: 3,
  maxRounds: 25,
  waves: 1,
  healBetweenWavesPercent: 0,
  ownershipRequired: false,
  rankingEligible: false,
  opponent: 'ai',
  channel: 'both',
);

const List<ModeRules> kBuiltinModes = [
  kClassicClash,
  kOnlineClash,
  kSurvivalChallenge,
  kPvpClash,
  kBossRaidLocked,
  kDraftLocked,
];

ModeRules? modeByCode(String code, [List<ModeRules>? catalog]) {
  final list = catalog ?? kBuiltinModes;
  for (final m in list) {
    if (m.code == code) return m;
  }
  return null;
}

/// Apply between-wave recovery using integer percent of missing HP.
void applyBetweenWaveHeal({
  required int currentHp,
  required int maxHp,
  required int healPercent,
  required void Function(int newHp) setHp,
  required void Function(int newEn) setEn,
  required int currentEn,
  required int maxEn,
}) {
  if (healPercent <= 0 || currentHp <= 0) {
    setEn((currentEn + 1).clamp(0, maxEn));
    return;
  }
  final missing = maxHp - currentHp;
  final heal = (missing * healPercent) ~/ 100;
  setHp((currentHp + heal).clamp(0, maxHp));
  setEn((currentEn + 2).clamp(0, maxEn));
}

/// Deterministic enemy picks for survival wave (1-indexed).
List<String> survivalEnemyIds({
  required int wave,
  required List<String> rosterIds,
  required int teamSize,
}) {
  if (rosterIds.isEmpty) return const [];
  final reversed = rosterIds.reversed.toList();
  final offset = ((wave - 1) * teamSize) % reversed.length;
  final out = <String>[];
  for (var i = 0; i < teamSize; i++) {
    out.add(reversed[(offset + i) % reversed.length]);
  }
  return out;
}
