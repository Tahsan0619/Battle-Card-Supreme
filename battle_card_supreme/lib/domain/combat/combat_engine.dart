import '../models/card_definition.dart';
import 'combat_models.dart';

class ActionResult {
  const ActionResult({
    required this.ok,
    this.errorCode,
    this.events = const [],
  });

  final bool ok;
  final String? errorCode;
  final List<CombatEvent> events;
}

/// Pure turn-based combat. No Flutter imports. Integer math only.
class CombatEngine {
  CombatState startMatch({
    required List<CardDefinition> playerCards,
    required List<CardDefinition> enemyCards,
    int maxRounds = 30,
  }) {
    if (playerCards.isEmpty || enemyCards.isEmpty) {
      throw ArgumentError('Both sides need at least one card');
    }

    final player = <Combatant>[];
    for (var i = 0; i < playerCards.length; i++) {
      player.add(
        Combatant.fromCard(
          card: playerCards[i],
          side: CombatSide.player,
          instanceId: 'P$i',
        ),
      );
    }
    final enemy = <Combatant>[];
    for (var i = 0; i < enemyCards.length; i++) {
      enemy.add(
        Combatant.fromCard(
          card: enemyCards[i],
          side: CombatSide.enemy,
          instanceId: 'E$i',
        ),
      );
    }

    final state = CombatState(
      player: player,
      enemy: enemy,
      turnQueue: <String>[],
      maxRounds: maxRounds,
    );
    _rebuildQueue(state);
    state.log.add(const CombatEvent(message: 'Clash begins.'));
    return state;
  }

  ActionResult apply(CombatState state, CombatAction action) {
    if (state.outcome != MatchOutcome.ongoing) {
      return const ActionResult(ok: false, errorCode: 'MATCH_ENDED');
    }

    if (action.clientActionId != null) {
      if (state.seenActionIds.contains(action.clientActionId)) {
        return const ActionResult(ok: true, errorCode: 'IDEMPOTENT_REPLAY');
      }
      state.seenActionIds.add(action.clientActionId!);
    }

    if (action.type == ActionType.concede) {
      state.outcome = MatchOutcome.forfeitPlayer;
      const ev = CombatEvent(message: 'Commander conceded.');
      state.log.add(ev);
      return const ActionResult(ok: true, events: [ev]);
    }

    final actor = state.byId(action.actorId);
    if (actor == null || !actor.isAlive) {
      return const ActionResult(ok: false, errorCode: 'MATCH_ILLEGAL_ACTION');
    }

    final current = state.currentActor;
    if (current == null || current.instanceId != actor.instanceId) {
      return const ActionResult(ok: false, errorCode: 'MATCH_NOT_YOUR_TURN');
    }

    final events = <CombatEvent>[];

    switch (action.type) {
      case ActionType.basicAttack:
        final target = _resolveTarget(state, actor, action.targetId);
        if (target == null) {
          return const ActionResult(ok: false, errorCode: 'MATCH_ILLEGAL_TARGET');
        }
        events.addAll(_strike(actor, target, multiplierPercent: 100));
        break;
      case ActionType.ability:
        final ability = actor.card.active;
        if (actor.abilityCooldown > 0) {
          return const ActionResult(ok: false, errorCode: 'MATCH_ILLEGAL_ACTION');
        }
        if (actor.en < ability.enCost) {
          return const ActionResult(ok: false, errorCode: 'MATCH_ILLEGAL_ACTION');
        }
        actor.en -= ability.enCost;
        actor.abilityCooldown = ability.cooldownTurns;

        if (ability.healPercent > 0 || ability.shieldPercent > 0) {
          final allies = actor.side == CombatSide.player ? state.player : state.enemy;
          Combatant? healTarget;
          if (action.targetId != null) {
            healTarget = state.byId(action.targetId!);
            if (healTarget == null ||
                healTarget.side != actor.side ||
                !healTarget.isAlive) {
              return const ActionResult(
                ok: false,
                errorCode: 'MATCH_ILLEGAL_TARGET',
              );
            }
          } else {
            healTarget = allies.where((c) => c.isAlive).fold<Combatant?>(
              null,
              (best, c) {
                if (best == null) return c;
                return c.hp < best.hp ? c : best;
              },
            );
          }
          if (healTarget != null) {
            if (ability.healPercent > 0) {
              final heal = (healTarget.maxHp * ability.healPercent) ~/ 100;
              final before = healTarget.hp;
              healTarget.hp = (healTarget.hp + heal).clamp(0, healTarget.maxHp);
              final applied = healTarget.hp - before;
              events.add(
                CombatEvent(
                  message:
                      '${actor.card.name} heals ${healTarget.card.name} for $applied.',
                  healing: applied,
                  actorId: actor.instanceId,
                  targetId: healTarget.instanceId,
                ),
              );
            }
            if (ability.shieldPercent > 0) {
              final sh = (healTarget.maxHp * ability.shieldPercent) ~/ 100;
              healTarget.shield += sh;
              events.add(
                CombatEvent(
                  message:
                      '${actor.card.name} shields ${healTarget.card.name} for $sh.',
                  actorId: actor.instanceId,
                  targetId: healTarget.instanceId,
                ),
              );
            }
          }
        } else if (ability.isAoe) {
          final foes = actor.side == CombatSide.player ? state.enemy : state.player;
          for (final t in foes.where((c) => c.isAlive)) {
            events.addAll(
              _strike(actor, t, multiplierPercent: ability.multiplierPercent),
            );
          }
        } else {
          final target = _resolveTarget(state, actor, action.targetId);
          if (target == null) {
            return const ActionResult(
              ok: false,
              errorCode: 'MATCH_ILLEGAL_TARGET',
            );
          }
          events.addAll(
            _strike(actor, target, multiplierPercent: ability.multiplierPercent),
          );
        }
        break;
      case ActionType.endTurn:
        events.add(
          CombatEvent(
            message: '${actor.card.name} ends their turn.',
            actorId: actor.instanceId,
          ),
        );
        break;
      case ActionType.concede:
        break;
    }

    state.log.addAll(events);
    _tickCooldowns(actor);
    _advanceTurn(state);
    _evaluateOutcome(state);
    return ActionResult(ok: true, events: events);
  }

  List<CombatEvent> _strike(
    Combatant actor,
    Combatant target, {
    required int multiplierPercent,
  }) {
    final raw = (actor.atk * multiplierPercent) ~/ 100;
    final mitigated = raw - ((target.def * 50) ~/ 100);
    var damage = mitigated < 1 ? 1 : mitigated;

    var remaining = damage;
    if (target.shield > 0) {
      final absorbed = remaining < target.shield ? remaining : target.shield;
      target.shield -= absorbed;
      remaining -= absorbed;
    }
    if (remaining > 0) {
      target.hp -= remaining;
      if (target.hp < 0) target.hp = 0;
    }

    return [
      CombatEvent(
        message:
            '${actor.card.name} hits ${target.card.name} for $damage damage.',
        damage: damage,
        actorId: actor.instanceId,
        targetId: target.instanceId,
      ),
      if (!target.isAlive)
        CombatEvent(
          message: '${target.card.name} is defeated.',
          actorId: actor.instanceId,
          targetId: target.instanceId,
        ),
    ];
  }

  Combatant? _resolveTarget(
    CombatState state,
    Combatant actor,
    String? targetId,
  ) {
    final foes = actor.side == CombatSide.player ? state.enemy : state.player;
    if (targetId != null) {
      final t = state.byId(targetId);
      if (t == null || !t.isAlive || t.side == actor.side) return null;
      return t;
    }
    return foes.where((c) => c.isAlive).fold<Combatant?>(null, (best, c) {
      if (best == null) return c;
      return c.hp < best.hp ? c : best;
    });
  }

  void _tickCooldowns(Combatant actor) {
    if (actor.abilityCooldown > 0) {
      // Cooldown ticks at end of own action resolution.
    }
  }

  void _advanceTurn(CombatState state) {
    if (state.outcome != MatchOutcome.ongoing) return;

    // Reduce cooldowns for the actor who just acted.
    final acted = state.currentActor;
    if (acted != null && acted.abilityCooldown > 0) {
      // Cooldown was set this turn; decrement others.
    }
    for (final c in state.all) {
      if (c.instanceId == acted?.instanceId) continue;
      if (c.abilityCooldown > 0) c.abilityCooldown -= 1;
    }

    final aliveIds = state.all.where((c) => c.isAlive).map((c) => c.instanceId).toSet();
    if (aliveIds.isEmpty) {
      state.outcome = MatchOutcome.draw;
      return;
    }

    var guard = 0;
    do {
      state.queueIndex += 1;
      if (state.queueIndex >= state.turnQueue.length) {
        state.queueIndex = 0;
        state.round += 1;
        _rebuildQueue(state);
        if (state.round > state.maxRounds) {
          state.outcome = MatchOutcome.draw;
          state.log.add(const CombatEvent(message: 'Turn limit reached. Draw.'));
          return;
        }
      }
      guard += 1;
    } while (!aliveIds.contains(state.turnQueue[state.queueIndex]) && guard < 64);

    // Regen 1 EN per turn start for current actor.
    final next = state.currentActor;
    if (next != null && next.isAlive) {
      next.en = (next.en + 1).clamp(0, next.maxEn);
    }
  }

  void _rebuildQueue(CombatState state) {
    final living = state.all.where((c) => c.isAlive).toList()
      ..sort((a, b) {
        final spd = b.spd.compareTo(a.spd);
        if (spd != 0) return spd;
        return a.instanceId.compareTo(b.instanceId);
      });
    state.turnQueue
      ..clear()
      ..addAll(living.map((c) => c.instanceId));
    if (state.queueIndex >= state.turnQueue.length) {
      state.queueIndex = 0;
    }
  }

  void _evaluateOutcome(CombatState state) {
    if (state.outcome != MatchOutcome.ongoing) return;
    final playerAlive = state.player.any((c) => c.isAlive);
    final enemyAlive = state.enemy.any((c) => c.isAlive);
    if (!playerAlive && !enemyAlive) {
      state.outcome = MatchOutcome.draw;
      state.log.add(const CombatEvent(message: 'Mutual defeat. Draw.'));
    } else if (!playerAlive) {
      state.outcome = MatchOutcome.victoryEnemy;
      state.log.add(const CombatEvent(message: 'Defeat.'));
    } else if (!enemyAlive) {
      state.outcome = MatchOutcome.victoryPlayer;
      state.log.add(const CombatEvent(message: 'Victory.'));
    }
  }
}

/// Deterministic damage helper for tests.
int computeDamage({
  required int atk,
  required int def,
  required int multiplierPercent,
}) {
  final raw = (atk * multiplierPercent) ~/ 100;
  final mitigated = raw - ((def * 50) ~/ 100);
  return mitigated < 1 ? 1 : mitigated;
}
