import '../models/card_definition.dart';

enum CombatSide { player, enemy }

enum MatchOutcome {
  ongoing,
  victoryPlayer,
  victoryEnemy,
  draw,
  forfeitPlayer,
}

enum ActionType { basicAttack, ability, endTurn, concede }

class Combatant {
  Combatant({
    required this.instanceId,
    required this.card,
    required this.side,
    required this.hp,
    required this.maxHp,
    required this.atk,
    required this.def,
    required this.spd,
    required this.en,
    required this.maxEn,
  });

  final String instanceId;
  final CardDefinition card;
  final CombatSide side;
  int hp;
  final int maxHp;
  final int atk;
  final int def;
  final int spd;
  int en;
  final int maxEn;
  int shield = 0;
  int abilityCooldown = 0;
  bool get isAlive => hp > 0;

  factory Combatant.fromCard({
    required CardDefinition card,
    required CombatSide side,
    required String instanceId,
  }) {
    return Combatant(
      instanceId: instanceId,
      card: card,
      side: side,
      hp: card.stats.hp,
      maxHp: card.stats.hp,
      atk: card.stats.atk,
      def: card.stats.def,
      spd: card.stats.spd,
      en: card.stats.en,
      maxEn: card.stats.en,
    );
  }
}

class CombatAction {
  const CombatAction({
    required this.type,
    required this.actorId,
    this.targetId,
    this.clientActionId,
  });

  final ActionType type;
  final String actorId;
  final String? targetId;
  final String? clientActionId;
}

class CombatEvent {
  const CombatEvent({
    required this.message,
    this.damage = 0,
    this.healing = 0,
    this.actorId,
    this.targetId,
  });

  final String message;
  final int damage;
  final int healing;
  final String? actorId;
  final String? targetId;
}

class CombatState {
  CombatState({
    required this.player,
    required this.enemy,
    required this.turnQueue,
    this.round = 1,
    this.queueIndex = 0,
    this.outcome = MatchOutcome.ongoing,
    this.maxRounds = 30,
    List<CombatEvent>? log,
    Set<String>? seenActionIds,
  })  : log = log ?? <CombatEvent>[],
        seenActionIds = seenActionIds ?? <String>{};

  final List<Combatant> player;
  final List<Combatant> enemy;
  final List<String> turnQueue;
  int round;
  int queueIndex;
  MatchOutcome outcome;
  final int maxRounds;
  final List<CombatEvent> log;
  final Set<String> seenActionIds;

  List<Combatant> get all => [...player, ...enemy];

  Combatant? byId(String id) {
    for (final c in all) {
      if (c.instanceId == id) return c;
    }
    return null;
  }

  Combatant? get currentActor {
    if (outcome != MatchOutcome.ongoing || turnQueue.isEmpty) return null;
    return byId(turnQueue[queueIndex % turnQueue.length]);
  }

  bool get isPlayerTurn {
    final a = currentActor;
    return a != null && a.side == CombatSide.player && a.isAlive;
  }
}
