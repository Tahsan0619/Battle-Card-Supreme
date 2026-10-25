import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/combat/combat_engine.dart';
import '../../domain/combat/combat_models.dart';
import '../../state/game_controllers.dart';
import '../../theme/aetherium_theme.dart';
import '../widgets/card_art.dart';
import '../widgets/vital_bar.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  String? _selectedTargetId;
  bool _logOpen = false;
  bool _actionLock = false;

  Future<void> _run(Future<void> Function() fn) async {
    if (_actionLock) return;
    setState(() => _actionLock = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _actionLock = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchProvider);
    final mode = ref.watch(activeModeProvider);
    final survival = ref.watch(survivalRunProvider);
    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('DUEL')),
        body: const Center(child: Text('No active match.')),
      );
    }

    if (match.outcome != MatchOutcome.ongoing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished();
      });
    }

    final actor = match.currentActor;
    final canAct = match.isPlayerTurn && !_actionLock;
    final title = survival != null
        ? 'SURVIVAL WAVE ${survival.wave}/${survival.wavesTotal}'
        : 'LIVE TACTICAL DUEL';

    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${mode.title} · round ${match.round}/${match.maxRounds}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AetheriumColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _actionLock
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Concede?'),
                        content: const Text(
                          'This ends the clash as a forfeit.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('CANCEL'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('CONCEDE'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && mounted) {
                      await _run(() async {
                        ref.read(matchProvider.notifier).act(
                              CombatAction(
                                type: ActionType.concede,
                                actorId: actor?.instanceId ?? 'P0',
                                clientActionId:
                                    'concede-${DateTime.now().millisecondsSinceEpoch}',
                              ),
                            );
                        widget.onFinished();
                      });
                    }
                  },
            child: Text(
              'FLAG',
              style: GoogleFonts.spaceGrotesk(
                color: AetheriumColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            color: AetheriumColors.surfaceLow.withValues(alpha: 0.95),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AetheriumColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TURN ${match.round}  ·  ${match.isPlayerTurn ? 'PLAYER' : 'ENEMY'}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AetheriumColors.secondary,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _logOpen = !_logOpen),
                  child: const Text('LOG'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  'ENEMY LINE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: 8),
                ...match.enemy.map(
                  (c) => _unitCard(
                    c,
                    selectable: canAct && c.isAlive,
                    selected: _selectedTargetId == c.instanceId,
                    onSelect: () =>
                        setState(() => _selectedTargetId = c.instanceId),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'YOUR VANGUARD',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06,
                  ),
                ),
                const SizedBox(height: 8),
                ...match.player.map((c) => _unitCard(c)),
                if (_logOpen) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 140,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AetheriumColors.surfaceLowest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      children: match.log.reversed
                          .take(40)
                          .map(
                            (e) => Text(
                              e.message,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AetheriumColors.onSurfaceVariant,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  if (actor != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Acting: ${actor.card.name}  ·  EN ${actor.en}/${actor.maxEn}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: !canAct || actor == null
                              ? null
                              : () => _run(() async {
                                    final r = ref.read(matchProvider.notifier).act(
                                          CombatAction(
                                            type: ActionType.basicAttack,
                                            actorId: actor.instanceId,
                                            targetId: _selectedTargetId,
                                            clientActionId:
                                                'atk-${match.round}-${match.queueIndex}-${DateTime.now().microsecondsSinceEpoch}',
                                          ),
                                        );
                                    _toastResult(r);
                                  }),
                          child: const Text('ATTACK'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: !canAct || actor == null
                              ? null
                              : () => _run(() async {
                                    final r = ref.read(matchProvider.notifier).act(
                                          CombatAction(
                                            type: ActionType.ability,
                                            actorId: actor.instanceId,
                                            targetId: _selectedTargetId,
                                            clientActionId:
                                                'abl-${match.round}-${match.queueIndex}-${DateTime.now().microsecondsSinceEpoch}',
                                          ),
                                        );
                                    _toastResult(r);
                                  }),
                          child: Text(
                            actor == null ? 'ABILITY' : actor.card.active.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: !canAct || actor == null
                          ? null
                          : () => _run(() async {
                                ref.read(matchProvider.notifier).act(
                                      CombatAction(
                                        type: ActionType.endTurn,
                                        actorId: actor.instanceId,
                                        clientActionId:
                                            'end-${match.round}-${match.queueIndex}',
                                      ),
                                    );
                              }),
                      child: const Text('END TURN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toastResult(ActionResult? r) {
    if (r == null || r.ok || r.errorCode == 'IDEMPOTENT_REPLAY') return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.errorCode ?? 'Action failed')),
    );
  }

  Widget _unitCard(
    Combatant c, {
    bool selectable = false,
    bool selected = false,
    VoidCallback? onSelect,
  }) {
    final dead = !c.isAlive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: selectable ? onSelect : null,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: dead
                ? AetheriumColors.surfaceHigh.withValues(alpha: 0.5)
                : AetheriumColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AetheriumColors.secondary
                  : AetheriumColors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: dead ? 0.45 : 1,
                child: CardArt(
                  card: c.card,
                  width: 52,
                  height: 60,
                  borderRadius: 6,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${c.card.name}${dead ? '  ·  DOWN' : ''}',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w600,
                              color: dead
                                  ? AetheriumColors.outline
                                  : AetheriumColors.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          'SPD ${c.spd}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            color: AetheriumColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    VitalBar(
                      label: 'HP',
                      value: c.hp,
                      max: c.maxHp,
                      color: AetheriumColors.hp,
                      shield: c.shield,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
