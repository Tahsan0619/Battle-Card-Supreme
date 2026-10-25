import 'dart:math';

import 'combat_models.dart';

/// Picks a legal action for the current enemy actor.
class SimpleCombatAi {
  SimpleCombatAi({Random? random}) : _random = random ?? Random(7);

  final Random _random;

  CombatAction choose(CombatState state) {
    final actor = state.currentActor;
    if (actor == null || actor.side != CombatSide.enemy || !actor.isAlive) {
      throw StateError('AI called off enemy turn');
    }

    final foes = state.player.where((c) => c.isAlive).toList();
    if (foes.isEmpty) {
      return CombatAction(type: ActionType.endTurn, actorId: actor.instanceId);
    }

    foes.sort((a, b) => a.hp.compareTo(b.hp));
    final target = foes.first;
    final ability = actor.card.active;
    final canAbility = actor.abilityCooldown <= 0 && actor.en >= ability.enCost;
    final preferAbility =
        canAbility && (ability.multiplierPercent >= 140 || _random.nextBool());

    if (preferAbility) {
      final support = ability.healPercent > 0 || ability.shieldPercent > 0;
      return CombatAction(
        type: ActionType.ability,
        actorId: actor.instanceId,
        targetId: support ? null : target.instanceId,
        clientActionId:
            'ai-${state.round}-${state.queueIndex}-${actor.instanceId}',
      );
    }

    return CombatAction(
      type: ActionType.basicAttack,
      actorId: actor.instanceId,
      targetId: target.instanceId,
      clientActionId:
          'ai-${state.round}-${state.queueIndex}-${actor.instanceId}-atk',
    );
  }
}
