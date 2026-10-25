import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_client.dart';
import 'session_controller.dart';

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.aether,
    required this.voidShards,
    required this.riftMarks,
    required this.keyIron,
    required this.keySilver,
    required this.keyGold,
    required this.energy,
    required this.energyMax,
    required this.balanceVersion,
  });

  final int level;
  final int xp;
  final int xpToNext;
  final int aether;
  final int voidShards;
  final int riftMarks;
  final int keyIron;
  final int keySilver;
  final int keyGold;
  final int energy;
  final int energyMax;
  final int balanceVersion;

  factory ProgressSnapshot.fromJson(Map<String, dynamic> body) {
    final profile = (body['profile'] as Map?)?.cast<String, dynamic>() ?? body;
    final keys = (profile['keys'] as Map?)?.cast<String, dynamic>() ?? {};
    return ProgressSnapshot(
      level: profile['level'] as int? ?? 1,
      xp: profile['xp'] as int? ?? 0,
      xpToNext: profile['xp_to_next'] as int? ?? 100,
      aether: profile['aether'] as int? ?? 0,
      voidShards: profile['void_shards'] as int? ?? 0,
      riftMarks: profile['rift_marks'] as int? ?? 0,
      keyIron: keys['iron'] as int? ?? 0,
      keySilver: keys['silver'] as int? ?? 0,
      keyGold: keys['gold'] as int? ?? 0,
      energy: profile['energy'] as int? ?? 0,
      energyMax: profile['energy_max'] as int? ?? 30,
      balanceVersion: body['balance_version'] as int? ?? 1,
    );
  }
}

class ProgressController extends AsyncNotifier<ProgressSnapshot?> {
  @override
  Future<ProgressSnapshot?> build() async {
    final session = await ref.watch(sessionProvider.future);
    if (!session.isAuthenticated) return null;
    try {
      final body = await ref.read(sessionProvider.notifier).client.progress();
      return ProgressSnapshot.fromJson(body);
    } on ApiException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }

  Future<Map<String, dynamic>?> claimVictory({
    required int matchId,
    required String clientClaimId,
  }) async {
    final client = ref.read(sessionProvider.notifier).client;
    final body = await client.claimMatchReward(
      matchId: matchId,
      clientClaimId: clientClaimId,
    );
    final profile = body['profile'] as Map<String, dynamic>?;
    if (profile != null) {
      state = AsyncData(ProgressSnapshot.fromJson({'profile': profile}));
    }
    return body;
  }
}

final progressProvider =
    AsyncNotifierProvider<ProgressController, ProgressSnapshot?>(
  ProgressController.new,
);
