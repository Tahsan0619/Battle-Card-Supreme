import 'package:battle_card_supreme/domain/combat/combat_engine.dart';
import 'package:battle_card_supreme/domain/combat/combat_models.dart';
import 'package:battle_card_supreme/domain/data/roster_seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final engine = CombatEngine();

  test('damage never below 1', () {
    expect(computeDamage(atk: 10, def: 500, multiplierPercent: 100), 1);
  });

  test('basic kill scenario eventually ends', () {
    final player = [cardById('l_sol_archon')!, cardById('c_ember_pike')!, cardById('r_kairo_ren')!];
    final enemy = [cardById('c_brine_ward')!, cardById('uc_glass_runner')!, cardById('c_ember_pike')!];
    final state = engine.startMatch(playerCards: player, enemyCards: enemy);

    var guard = 0;
    while (state.outcome == MatchOutcome.ongoing && guard < 200) {
      final actor = state.currentActor!;
      final foes = (actor.side == CombatSide.player ? state.enemy : state.player)
          .where((c) => c.isAlive)
          .toList();
      final target = foes.isEmpty ? null : foes.first.instanceId;
      engine.apply(
        state,
        CombatAction(
          type: ActionType.basicAttack,
          actorId: actor.instanceId,
          targetId: target,
          clientActionId: 't$guard',
        ),
      );
      guard += 1;
    }

    expect(state.outcome, isNot(MatchOutcome.ongoing));
  });

  test('illegal turn rejected', () {
    final state = engine.startMatch(
      playerCards: kSeedRoster.take(3).toList(),
      enemyCards: kSeedRoster.skip(3).take(3).toList(),
    );
    final notActor = state.all.firstWhere(
      (c) => c.instanceId != state.currentActor!.instanceId,
    );
    final result = engine.apply(
      state,
      CombatAction(
        type: ActionType.basicAttack,
        actorId: notActor.instanceId,
        clientActionId: 'bad',
      ),
    );
    expect(result.ok, isFalse);
    expect(result.errorCode, 'MATCH_NOT_YOUR_TURN');
  });

  test('idempotent replay accepted once', () {
    final state = engine.startMatch(
      playerCards: kSeedRoster.take(3).toList(),
      enemyCards: kSeedRoster.skip(3).take(3).toList(),
    );
    final actor = state.currentActor!;
    // Force player turn by skipping until player if needed.
    var hops = 0;
    while (actor.side != CombatSide.player &&
        state.outcome == MatchOutcome.ongoing &&
        hops < 10) {
      final a = state.currentActor!;
      final foes = (a.side == CombatSide.player ? state.enemy : state.player)
          .where((c) => c.isAlive);
      engine.apply(
        state,
        CombatAction(
          type: ActionType.basicAttack,
          actorId: a.instanceId,
          targetId: foes.isEmpty ? null : foes.first.instanceId,
          clientActionId: 'hop$hops',
        ),
      );
      hops += 1;
    }
    if (state.currentActor?.side != CombatSide.player) return;

    final a = state.currentActor!;
    final foes = state.enemy.where((c) => c.isAlive);
    final action = CombatAction(
      type: ActionType.basicAttack,
      actorId: a.instanceId,
      targetId: foes.first.instanceId,
      clientActionId: 'same-key',
    );
    final first = engine.apply(state, action);
    expect(first.ok, isTrue);
    final second = engine.apply(state, action);
    expect(second.ok, isTrue);
    expect(second.errorCode, 'IDEMPOTENT_REPLAY');
  });

  test('shield absorbs damage', () {
    final state = engine.startMatch(
      playerCards: [cardById('sr_astra_veyron')!],
      enemyCards: [cardById('c_ember_pike')!],
      maxRounds: 5,
    );
    final astra = state.player.first;
    astra.shield = 50;
    final beforeHp = astra.hp;
    // Make enemy act if needed.
    while (state.currentActor?.side != CombatSide.enemy &&
        state.outcome == MatchOutcome.ongoing) {
      final a = state.currentActor!;
      engine.apply(
        state,
        CombatAction(
          type: ActionType.endTurn,
          actorId: a.instanceId,
          clientActionId: 'skip-${a.instanceId}-${state.queueIndex}',
        ),
      );
    }
    if (state.outcome != MatchOutcome.ongoing) return;
    final enemy = state.currentActor!;
    engine.apply(
      state,
      CombatAction(
        type: ActionType.basicAttack,
        actorId: enemy.instanceId,
        targetId: astra.instanceId,
        clientActionId: 'hit-shield',
      ),
    );
    expect(astra.shield, lessThan(50));
    expect(astra.hp, greaterThanOrEqualTo(beforeHp - 200));
    expect(astra.isAlive, isTrue);
  });
}
