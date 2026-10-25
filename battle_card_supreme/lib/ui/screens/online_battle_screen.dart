import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/api/api_client.dart';
import '../../state/game_controllers.dart';
import '../../state/session_controller.dart';
import '../../domain/data/roster_seed.dart';
import '../../theme/aetherium_theme.dart';
import '../widgets/card_art.dart';
import '../widgets/vital_bar.dart';

class OnlineBattleScreen extends ConsumerStatefulWidget {
  const OnlineBattleScreen({
    super.key,
    required this.onFinished,
    this.existingMatchId,
  });

  final VoidCallback onFinished;
  final int? existingMatchId;

  @override
  ConsumerState<OnlineBattleScreen> createState() => _OnlineBattleScreenState();
}

class _OnlineBattleScreenState extends ConsumerState<OnlineBattleScreen> {
  Map<String, dynamic>? _match;
  String? _error;
  bool _busy = false;
  String? _selectedTargetId;
  Timer? _poll;

  int get _matchId => _match?['id'] as int;
  int get _version => _match?['state_version'] as int? ?? 0;
  Map<String, dynamic> get _state =>
      (_match?['state'] as Map<String, dynamic>?) ?? const {};
  String get _seat => _match?['your_seat'] as String? ?? 'player';
  bool get _isPvp => _match?['is_pvp'] == true;
  bool get _hostTurn => _state['is_player_turn'] as bool? ?? false;
  bool get _myTurn => _seat == 'player' ? _hostTurn : !_hostTurn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _ensurePoll() {
    if (!_isPvp) return;
    _poll ??= Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _busy || _match == null) return;
      if ((_state['outcome'] as String? ?? '') != 'ongoing') return;
      if (_myTurn) return;
      try {
        final body = await ref
            .read(sessionProvider.notifier)
            .client
            .getMatch(_matchId);
        if (!mounted) return;
        setState(() => _match = body['match'] as Map<String, dynamic>);
        _maybeFinish();
      } catch (_) {}
    });
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(sessionProvider.notifier).client;
      if (widget.existingMatchId != null) {
        final body = await client.getMatch(widget.existingMatchId!);
        setState(() => _match = body['match'] as Map<String, dynamic>);
      } else {
        final localIds = ref.read(teamProvider).value;
        List<String>? onlineCodes;
        if (localIds != null && localIds.length == kBattleTeamSize) {
          try {
            await client.syncTeam(cardCodes: localIds);
            onlineCodes = localIds;
          } on ApiException catch (e) {
            if (e.code != 'CARD_NOT_OWNED') rethrow;
          }
        }
        final body = await client.createMatch(cardCodes: onlineCodes);
        setState(() => _match = body['match'] as Map<String, dynamic>);
      }
      _ensurePoll();
      _maybeFinish();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to open online match.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _maybeFinish() {
    final outcome = _state['outcome'] as String? ?? 'ongoing';
    if (outcome != 'ongoing') {
      _poll?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _match == null) return;
        ref.read(onlineResultProvider.notifier).setResult(
              Map<String, dynamic>.from(_match!),
            );
        widget.onFinished();
      });
    }
  }

  Future<void> _act(String type) async {
    if (_busy || _match == null) return;
    final actorId = _state['current_actor_id'] as String?;
    if (actorId == null && type != 'concede') return;
    setState(() => _busy = true);
    try {
      final client = ref.read(sessionProvider.notifier).client;
      final body = await client.matchAction(
        matchId: _matchId,
        type: type,
        actorId: actorId ?? (_seat == 'player' ? 'P0' : 'E0'),
        targetId: _selectedTargetId,
        clientActionId:
            '$type-$actorId-$_version-${DateTime.now().microsecondsSinceEpoch}',
        stateVersion: _version,
      );
      setState(() => _match = body['match'] as Map<String, dynamic>);
      _maybeFinish();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.code}: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ONLINE DUEL')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _start, child: const Text('RETRY')),
              ],
            ),
          ),
        ),
      );
    }

    if (_match == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canAct = _myTurn &&
        (_state['outcome'] as String? ?? '') == 'ongoing' &&
        !_busy;

    final foes = _seat == 'player'
        ? ((_state['enemy'] as List?) ?? [])
        : ((_state['player'] as List?) ?? []);
    final allies = _seat == 'player'
        ? ((_state['player'] as List?) ?? [])
        : ((_state['enemy'] as List?) ?? []);

    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      appBar: AppBar(
        title: Text(_isPvp ? 'PvP DUEL' : 'ONLINE TACTICAL DUEL'),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Concede?'),
                        content: const Text('Server will record a forfeit.'),
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
                    if (ok == true) await _act('concede');
                  },
            child: Text(
              'FLAG',
              style: GoogleFonts.spaceGrotesk(color: AetheriumColors.error),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'MATCH #$_matchId  ·  v$_version  ·  TURN ${_state['round']}  ·  '
              '${_myTurn ? 'YOUR TURN' : 'WAITING'}  ·  seat $_seat',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AetheriumColors.secondary,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Text(
                  'OPPONENT',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                ),
                ...foes.map((raw) {
                  final c = Map<String, dynamic>.from(raw as Map);
                  return _unit(
                    c,
                    selectable: canAct && (c['is_alive'] as bool? ?? false),
                  );
                }),
                const SizedBox(height: 12),
                Text(
                  'YOU',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                ),
                ...allies.map((raw) {
                  final c = Map<String, dynamic>.from(raw as Map);
                  return _unit(c);
                }),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: canAct ? () => _act('basic_attack') : null,
                      child: const Text('ATTACK'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canAct ? () => _act('ability') : null,
                      child: const Text('ABILITY'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canAct ? () => _act('end_turn') : null,
                      child: const Text('END'),
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

  Widget _unit(Map<String, dynamic> c, {bool selectable = false}) {
    final id = c['instance_id'] as String? ?? '';
    final selected = _selectedTargetId == id;
    final alive = c['is_alive'] as bool? ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: selectable ? () => setState(() => _selectedTargetId = id) : null,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AetheriumColors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AetheriumColors.secondary
                  : AetheriumColors.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (_) {
                  final code = c['card_code'] as String? ??
                      c['definition_code'] as String? ??
                      '';
                  final def = cardById(code);
                  if (def == null) {
                    return const SizedBox(width: 52, height: 60);
                  }
                  return Opacity(
                    opacity: alive ? 1 : 0.45,
                    child: CardArt(
                      card: def,
                      width: 52,
                      height: 60,
                      borderRadius: 6,
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c['name']}${alive ? '' : '  ·  DOWN'}',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    VitalBar(
                      label: 'HP',
                      value: c['hp'] as int? ?? 0,
                      max: c['max_hp'] as int? ?? 1,
                      color: AetheriumColors.hp,
                      shield: c['shield'] as int? ?? 0,
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
