import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_client.dart';
import 'meta_controller.dart';
import 'session_controller.dart';

class RankingEntry {
  const RankingEntry({
    required this.userId,
    required this.seasonCode,
    required this.rating,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.matches,
    this.rank,
    this.displayName,
  });

  final int userId;
  final String seasonCode;
  final int rating;
  final int wins;
  final int losses;
  final int draws;
  final int matches;
  final int? rank;
  final String? displayName;

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      userId: json['user_id'] as int? ?? 0,
      seasonCode: json['season_code'] as String? ?? 'foundation',
      rating: json['rating'] as int? ?? 1000,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      matches: json['matches'] as int? ?? 0,
      rank: json['rank'] as int?,
      displayName: json['display_name'] as String?,
    );
  }
}

class LeaderboardSnapshot {
  const LeaderboardSnapshot({
    required this.seasonCode,
    required this.entries,
    this.me,
  });

  final String seasonCode;
  final List<RankingEntry> entries;
  final RankingEntry? me;
}

class RankingController extends AsyncNotifier<LeaderboardSnapshot?> {
  @override
  Future<LeaderboardSnapshot?> build() async {
    final meta = await ref.watch(metaProvider.future);
    if (!meta.flag('ranking', fallback: true)) return null;

    try {
      final client = ref.read(sessionProvider.notifier).client;
      final board = await client.leaderboard();
      final raw = (board['entries'] as List?) ?? const [];
      final entries = raw
          .whereType<Map>()
          .map((e) => RankingEntry.fromJson(e.cast<String, dynamic>()))
          .toList();

      RankingEntry? me;
      final session = ref.watch(sessionProvider).value;
      if (session?.isAuthenticated == true) {
        try {
          final body = await client.rankingMe();
          final rating = (body['rating'] as Map?)?.cast<String, dynamic>();
          if (rating != null) me = RankingEntry.fromJson(rating);
        } on ApiException {
          // Leaderboard still useful without me.
        }
      }

      return LeaderboardSnapshot(
        seasonCode: board['season_code'] as String? ?? 'foundation',
        entries: entries,
        me: me,
      );
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
}

final rankingProvider =
    AsyncNotifierProvider<RankingController, LeaderboardSnapshot?>(
  RankingController.new,
);
