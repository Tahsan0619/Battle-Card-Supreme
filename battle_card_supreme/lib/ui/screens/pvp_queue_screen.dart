import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/api/api_client.dart';
import '../../state/game_controllers.dart';
import '../../state/session_controller.dart';
import '../../theme/aetherium_theme.dart';

class PvpQueueScreen extends ConsumerStatefulWidget {
  const PvpQueueScreen({
    super.key,
    required this.onMatchReady,
    required this.onBack,
  });

  final void Function(int matchId) onMatchReady;
  final VoidCallback onBack;

  @override
  ConsumerState<PvpQueueScreen> createState() => _PvpQueueScreenState();
}

class _PvpQueueScreenState extends ConsumerState<PvpQueueScreen> {
  Map<String, dynamic>? _status;
  String? _error;
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(sessionProvider.notifier).client;
      final ids = ref.read(teamProvider).value;
      final body = await client.pvpEnqueue(
        cardCodes: ids != null && ids.length == kBattleTeamSize ? ids : null,
      );
      if (!mounted) return;
      setState(() => _status = body);
      _handleStatus(body);
      _startPoll();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to join PvP queue.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final body = await ref.read(sessionProvider.notifier).client.pvpStatus();
      if (!mounted) return;
      setState(() => _status = body);
      _handleStatus(body);
    } catch (_) {}
  }

  void _handleStatus(Map<String, dynamic> body) {
    final matchId = body['match_id'] as int?;
    final offer = body['offer'] as Map?;
    if (matchId != null) {
      _poll?.cancel();
      widget.onMatchReady(matchId);
      return;
    }
    if (offer != null && offer['match_id'] != null) {
      _poll?.cancel();
      widget.onMatchReady(offer['match_id'] as int);
    }
  }

  Future<void> _accept() async {
    final offerId = (_status?['offer'] as Map?)?['id'] as int?;
    if (offerId == null) return;
    setState(() => _busy = true);
    try {
      final body =
          await ref.read(sessionProvider.notifier).client.pvpAccept(offerId);
      if (!mounted) return;
      setState(() => _status = body);
      _handleStatus(body);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    final offerId = (_status?['offer'] as Map?)?['id'] as int?;
    if (offerId == null) return;
    setState(() => _busy = true);
    try {
      final body =
          await ref.read(sessionProvider.notifier).client.pvpDecline(offerId);
      if (!mounted) return;
      setState(() => _status = body);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    _poll?.cancel();
    try {
      await ref.read(sessionProvider.notifier).client.pvpLeaveQueue();
    } catch (_) {}
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final offer = (_status?['offer'] as Map?)?.cast<String, dynamic>();
    final queue = (_status?['queue'] as Map?)?.cast<String, dynamic>();
    final window = _status?['accept_window_seconds'] as int? ?? 30;

    return Scaffold(
      backgroundColor: AetheriumColors.surface,
      appBar: AppBar(
        title: const Text('PvP QUEUE'),
        leading: IconButton(
          onPressed: _leave,
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PvP CARD CLASH',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AetheriumColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Server pairs commanders. Accept within $window seconds.',
              style: GoogleFonts.plusJakartaSans(
                color: AetheriumColors.onSurfaceVariant,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: AetheriumColors.error)),
            ],
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 24),
            if (offer != null) ...[
              Text(
                'MATCH FOUND',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  color: AetheriumColors.secondary,
                ),
              ),
              Text(
                'You are seat ${offer['you_are']}. '
                'Accepted: A=${offer['accept_a']} B=${offer['accept_b']}',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (offer['you_accepted'] != true)
                FilledButton(
                  onPressed: _busy ? null : _accept,
                  child: const Text('ACCEPT DUEL'),
                ),
              if (offer['you_accepted'] == true)
                Text(
                  'Waiting for opponent accept…',
                  style: GoogleFonts.plusJakartaSans(
                    color: AetheriumColors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : _decline,
                child: const Text('DECLINE'),
              ),
            ] else ...[
              Text(
                queue == null
                    ? 'Not in queue.'
                    : 'Searching… status ${queue['status']}',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (queue == null)
                FilledButton(
                  onPressed: _busy ? null : _join,
                  child: const Text('REJOIN QUEUE'),
                ),
            ],
            const Spacer(),
            OutlinedButton(
              onPressed: _leave,
              child: const Text('LEAVE'),
            ),
          ],
        ),
      ),
    );
  }
}
