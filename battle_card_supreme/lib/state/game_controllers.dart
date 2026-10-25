import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/combat/combat_engine.dart';
import '../domain/combat/combat_models.dart';
import '../domain/combat/simple_ai.dart';
import '../domain/data/roster_seed.dart';
import '../domain/modes/mode_rules.dart';
import '../domain/models/card_definition.dart';
import 'collection_controller.dart';
import 'team_storage.dart';

const int kBattleTeamSize = 3;

final catalogueProvider = Provider<List<CardDefinition>>((ref) => kSeedRoster);

final teamStorageProvider = Provider<TeamStorage>((ref) => TeamStorage());

class TeamNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final collection = await ref.watch(collectionProvider.future);
    final owned = collection.ownedIds;
    final stored = await ref.read(teamStorageProvider).load();
    if (stored != null && stored.isNotEmpty) {
      final valid = stored
          .where((id) => cardById(id) != null && owned.contains(id))
          .toList();
      if (valid.isNotEmpty) return valid;
    }
    return owned.take(kBattleTeamSize).toList();
  }

  List<String> get ids => state.value ?? const [];

  String? validate([List<String>? override]) {
    final current = override ?? ids;
    final owned =
        ref.read(collectionProvider).value?.ownedIds ?? const <String>{};
    if (current.length < kBattleTeamSize) {
      return 'Need $kBattleTeamSize owned fighters in the squad.';
    }
    if (current.length > kBattleTeamSize) {
      return 'Squad is full ($kBattleTeamSize).';
    }
    if (current.toSet().length != current.length) {
      return 'Duplicate characters are not allowed in Classic Clash.';
    }
    for (final id in current) {
      if (cardById(id) == null) return 'Unknown card in squad.';
      if (!owned.contains(id)) return 'Squad has locked cards. Unlock via Exchange.';
    }
    return null;
  }

  Future<void> _persist(List<String> next) async {
    state = AsyncData(next);
    await ref.read(teamStorageProvider).save(next);
  }

  Future<bool> add(String id) async {
    final current = List<String>.from(ids);
    if (current.contains(id)) return false;
    if (current.length >= kBattleTeamSize) return false;
    if (cardById(id) == null) return false;
    final owned =
        ref.read(collectionProvider).value?.ownedIds ?? const <String>{};
    if (!owned.contains(id)) return false;
    current.add(id);
    await _persist(current);
    return true;
  }

  Future<void> remove(String id) async {
    await _persist(ids.where((e) => e != id).toList());
  }

  Future<void> clear() async {
    await _persist([]);
  }

  Future<void> setIds(List<String> next) async {
    await _persist(List<String>.from(next));
  }
}

final teamProvider =
    AsyncNotifierProvider<TeamNotifier, List<String>>(TeamNotifier.new);

enum GameModeId {
  classicClash,
  onlineClash,
  survivalChallenge,
  pvpClash,
  bossRaidLocked,
  draftLocked,
}

GameModeId gameModeIdFromCode(String code) {
  return switch (code) {
    'online_clash' => GameModeId.onlineClash,
    'survival_challenge' => GameModeId.survivalChallenge,
    'pvp_clash' => GameModeId.pvpClash,
    'boss_raid' => GameModeId.bossRaidLocked,
    'draft_challenge' => GameModeId.draftLocked,
    _ => GameModeId.classicClash,
  };
}

class GameModeInfo {
  const GameModeInfo({
    required this.id,
    required this.rules,
  });

  final GameModeId id;
  final ModeRules rules;

  String get title => rules.title;
  String get subtitle => rules.subtitle;
  bool get available => rules.available;
  String get code => rules.code;
}

List<GameModeInfo> get kGameModes => [
      GameModeInfo(id: GameModeId.classicClash, rules: kClassicClash),
      GameModeInfo(id: GameModeId.onlineClash, rules: kOnlineClash),
      GameModeInfo(
        id: GameModeId.survivalChallenge,
        rules: kSurvivalChallenge,
      ),
      GameModeInfo(id: GameModeId.pvpClash, rules: kPvpClash),
      GameModeInfo(id: GameModeId.bossRaidLocked, rules: kBossRaidLocked),
      GameModeInfo(id: GameModeId.draftLocked, rules: kDraftLocked),
    ];

class ActiveModeNotifier extends Notifier<ModeRules> {
  @override
  ModeRules build() => kClassicClash;

  void setMode(ModeRules mode) => state = mode;
}

final activeModeProvider =
    NotifierProvider<ActiveModeNotifier, ModeRules>(ActiveModeNotifier.new);

class SurvivalRun {
  const SurvivalRun({
    required this.wave,
    required this.wavesTotal,
    required this.cleared,
    required this.failed,
    required this.complete,
  });

  final int wave;
  final int wavesTotal;
  final int cleared;
  final bool failed;
  final bool complete;
}

class SurvivalRunNotifier extends Notifier<SurvivalRun?> {
  @override
  SurvivalRun? build() => null;

  void begin(ModeRules rules) {
    state = SurvivalRun(
      wave: 1,
      wavesTotal: rules.waves,
      cleared: 0,
      failed: false,
      complete: false,
    );
  }

  void markWaveCleared() {
    final s = state;
    if (s == null) return;
    final cleared = s.cleared + 1;
    if (cleared >= s.wavesTotal) {
      state = SurvivalRun(
        wave: s.wave,
        wavesTotal: s.wavesTotal,
        cleared: cleared,
        failed: false,
        complete: true,
      );
      return;
    }
    state = SurvivalRun(
      wave: s.wave + 1,
      wavesTotal: s.wavesTotal,
      cleared: cleared,
      failed: false,
      complete: false,
    );
  }

  void markFailed() {
    final s = state;
    if (s == null) return;
    state = SurvivalRun(
      wave: s.wave,
      wavesTotal: s.wavesTotal,
      cleared: s.cleared,
      failed: true,
      complete: true,
    );
  }

  void clear() => state = null;
}

final survivalRunProvider =
    NotifierProvider<SurvivalRunNotifier, SurvivalRun?>(
  SurvivalRunNotifier.new,
);

class MatchController extends Notifier<CombatState?> {
  final CombatEngine engine = CombatEngine();
  final SimpleCombatAi ai = SimpleCombatAi();
  bool _busy = false;
  List<Combatant>? _carriedPlayer;

  @override
  CombatState? build() => null;

  String? startVsAi({
    List<String>? playerIds,
    List<String>? enemyIds,
    ModeRules? mode,
    bool carryHp = false,
  }) {
    final ModeRules rules = mode ?? ref.read(activeModeProvider);
    final teamAsync = ref.read(teamProvider);
    final List<String> team = playerIds ??
        List<String>.from(teamAsync.value ?? const <String>[]);
    final teamError = ref.read(teamProvider.notifier).validate(team);
    if (teamError != null) return teamError;

    final playerCards = cardsByIds(team);
    if (playerCards.length < rules.teamSize) {
      return 'Need ${rules.teamSize} owned cards.';
    }

    final enemyPool = enemyIds ??
        kSeedRoster.reversed.take(rules.teamSize).map((c) => c.id).toList();
    final enemyCards = cardsByIds(enemyPool);
    state = engine.startMatch(
      playerCards: playerCards,
      enemyCards: enemyCards,
      maxRounds: rules.maxRounds,
    );

    if (carryHp && _carriedPlayer != null) {
      _restoreCarriedPlayer(state!, rules);
    }

    _drainEnemyTurns();
    return null;
  }

  String? startSurvivalWave({List<String>? playerIds}) {
    final rules = kSurvivalChallenge;
    ref.read(activeModeProvider.notifier).setMode(rules);
    final run = ref.read(survivalRunProvider);
    final wave = run?.wave ?? 1;
    if (run == null) {
      ref.read(survivalRunProvider.notifier).begin(rules);
    }
    final rosterIds = kSeedRoster.map((c) => c.id).toList();
    final enemies = survivalEnemyIds(
      wave: wave,
      rosterIds: rosterIds,
      teamSize: rules.teamSize,
    );
    return startVsAi(
      playerIds: playerIds,
      enemyIds: enemies,
      mode: rules,
      carryHp: wave > 1,
    );
  }

  /// After a survival wave victory, heal survivors and advance wave counter.
  /// Returns true when another wave should start.
  bool advanceSurvivalAfterVictory() {
    final s = state;
    final rules = ref.read(activeModeProvider);
    if (s == null || s.outcome != MatchOutcome.victoryPlayer) return false;

    _carriedPlayer = s.player
        .map(
          (c) => Combatant(
            instanceId: c.instanceId,
            card: c.card,
            side: c.side,
            hp: c.hp,
            maxHp: c.maxHp,
            atk: c.atk,
            def: c.def,
            spd: c.spd,
            en: c.en,
            maxEn: c.maxEn,
          )
            ..shield = c.shield
            ..abilityCooldown = c.abilityCooldown,
        )
        .toList();

    for (final c in _carriedPlayer!) {
      if (!c.isAlive) continue;
      applyBetweenWaveHeal(
        currentHp: c.hp,
        maxHp: c.maxHp,
        healPercent: rules.healBetweenWavesPercent,
        setHp: (v) => c.hp = v,
        setEn: (v) => c.en = v,
        currentEn: c.en,
        maxEn: c.maxEn,
      );
      c.shield = 0;
    }

    ref.read(survivalRunProvider.notifier).markWaveCleared();
    final next = ref.read(survivalRunProvider);
    return next != null && !next.complete;
  }

  void noteSurvivalFailure() {
    ref.read(survivalRunProvider.notifier).markFailed();
    _carriedPlayer = null;
  }

  void clearSurvivalCarry() {
    _carriedPlayer = null;
    ref.read(survivalRunProvider.notifier).clear();
  }

  void _restoreCarriedPlayer(CombatState state, ModeRules rules) {
    final carried = _carriedPlayer;
    if (carried == null) return;
    for (var i = 0; i < state.player.length && i < carried.length; i++) {
      final src = carried[i];
      final dst = state.player[i];
      if (src.hp <= 0) {
        dst.hp = 0;
        continue;
      }
      dst.hp = src.hp.clamp(1, dst.maxHp);
      dst.en = src.en.clamp(0, dst.maxEn);
      dst.shield = 0;
      dst.abilityCooldown = src.abilityCooldown;
    }

    final living = state.all.where((c) => c.isAlive).toList()
      ..sort((a, b) {
        final spd = b.spd.compareTo(a.spd);
        if (spd != 0) return spd;
        return a.instanceId.compareTo(b.instanceId);
      });
    state.turnQueue
      ..clear()
      ..addAll(living.map((c) => c.instanceId));
    state.queueIndex = 0;
    state.round = 1;

    if (!state.player.any((c) => c.isAlive)) {
      state.outcome = MatchOutcome.victoryEnemy;
      state.log.add(const CombatEvent(message: 'No survivors remain.'));
      return;
    }

    state.log.add(
      CombatEvent(
        message:
            'Wave ${ref.read(survivalRunProvider)?.wave ?? '?'} begins. Survivors restored (${rules.healBetweenWavesPercent}% missing HP).',
      ),
    );
  }

  ActionResult? act(CombatAction action) {
    final s = state;
    if (s == null) return null;
    if (_busy) {
      return const ActionResult(ok: false, errorCode: 'BUSY');
    }
    _busy = true;
    try {
      if (!s.isPlayerTurn && action.type != ActionType.concede) {
        return const ActionResult(ok: false, errorCode: 'MATCH_NOT_YOUR_TURN');
      }
      final result = engine.apply(s, action);
      state = s;
      if (result.ok && s.outcome == MatchOutcome.ongoing) {
        _drainEnemyTurns();
      }
      return result;
    } finally {
      _busy = false;
    }
  }

  void _drainEnemyTurns() {
    final s = state;
    if (s == null) return;
    var guard = 0;
    while (s.outcome == MatchOutcome.ongoing &&
        s.currentActor?.side == CombatSide.enemy &&
        guard < 40) {
      final action = ai.choose(s);
      engine.apply(s, action);
      guard += 1;
    }
    state = s;
  }

  void clear() => state = null;
}

final matchProvider =
    NotifierProvider<MatchController, CombatState?>(MatchController.new);

class RarityFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? value) => state = value;
}

final selectedRarityFilterProvider =
    NotifierProvider<RarityFilterNotifier, String?>(RarityFilterNotifier.new);

/// Last finished online match payload for the result screen.
class OnlineResultNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setResult(Map<String, dynamic>? value) => state = value;
}

final onlineResultProvider =
    NotifierProvider<OnlineResultNotifier, Map<String, dynamic>?>(
  OnlineResultNotifier.new,
);
