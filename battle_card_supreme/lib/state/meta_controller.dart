import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_client.dart';
import 'session_controller.dart';

/// App build version compared against server `min_app_version`.
const kAppVersion = '1.0.0';

class ServerMeta {
  const ServerMeta({
    required this.minAppVersion,
    required this.catalogueVersion,
    required this.balanceVersion,
    required this.flags,
    this.reachable = true,
  });

  final String minAppVersion;
  final int catalogueVersion;
  final int balanceVersion;
  final Map<String, bool> flags;
  final bool reachable;

  bool get forceUpgrade => isOlderThan(kAppVersion, minAppVersion);

  bool flag(String key, {bool fallback = false}) => flags[key] ?? fallback;

  static bool isOlderThan(String current, String minimum) {
    List<int> parts(String v) => v
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final a = parts(current);
    final b = parts(minimum);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av < bv) return true;
      if (av > bv) return false;
    }
    return false;
  }

  factory ServerMeta.fromJson(Map<String, dynamic> json) {
    final rawFlags = (json['feature_flags'] as Map?)?.cast<String, dynamic>() ?? {};
    final flags = <String, bool>{};
    for (final e in rawFlags.entries) {
      flags[e.key] = e.value == true;
    }
    return ServerMeta(
      minAppVersion: json['min_app_version'] as String? ?? '1.0.0',
      catalogueVersion: json['catalogue_version'] as int? ?? 1,
      balanceVersion: json['balance_version'] as int? ?? 1,
      flags: flags,
    );
  }

  static const offline = ServerMeta(
    minAppVersion: '1.0.0',
    catalogueVersion: 1,
    balanceVersion: 1,
    flags: {
      'shop': true,
      'summon': true,
      'pvp': true,
      'ranking': true,
      'guild': false,
      'online_clash': true,
      'survival_challenge': true,
      'rewards_claim': true,
    },
    reachable: false,
  );
}

class MetaController extends AsyncNotifier<ServerMeta> {
  @override
  Future<ServerMeta> build() async {
    try {
      await ref.watch(sessionProvider.future);
      final body = await ref
          .read(sessionProvider.notifier)
          .client
          .meta()
          .timeout(const Duration(milliseconds: 1500));
      return ServerMeta.fromJson(body);
    } on ApiException {
      return ServerMeta.offline;
    } catch (_) {
      return ServerMeta.offline;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}

final metaProvider =
    AsyncNotifierProvider<MetaController, ServerMeta>(MetaController.new);
