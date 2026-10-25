import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP client for the Laravel API (auth, catalogue, teams, matches).
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  String? accessToken;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool auth = false, bool jsonBody = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
    if (auth && accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await _http.post(
      _uri('/api/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    final body = _decode(res);
    accessToken = body['token'] as String?;
    return body;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _http.post(
      _uri('/api/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _decode(res);
    accessToken = body['token'] as String?;
    return body;
  }

  Future<void> logout() async {
    if (accessToken == null) return;
    try {
      await _http.post(_uri('/api/logout'), headers: _headers(auth: true));
    } finally {
      accessToken = null;
    }
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _http.get(_uri('/api/me'), headers: _headers(auth: true));
    return _decode(res);
  }

  Future<Map<String, dynamic>> progress() async {
    final res =
        await _http.get(_uri('/api/progress'), headers: _headers(auth: true));
    return _decode(res);
  }

  Future<Map<String, dynamic>> leaderboard({int limit = 50}) async {
    final res = await _http.get(
      _uri('/api/leaderboard', {'limit': '$limit'}),
      headers: _headers(auth: false),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> rankingMe() async {
    final res = await _http.get(
      _uri('/api/ranking/me'),
      headers: _headers(auth: true),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> claimMatchReward({
    required int matchId,
    required String clientClaimId,
  }) async {
    final res = await _http.post(
      _uri('/api/matches/$matchId/rewards/claim'),
      headers: _headers(auth: true),
      body: jsonEncode({'client_claim_id': clientClaimId}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> shopCatalogue() async {
    final res =
        await _http.get(_uri('/api/shop'), headers: _headers(auth: true));
    return _decode(res);
  }

  Future<Map<String, dynamic>> shopPurchase({
    required String offerCode,
    required String clientPurchaseId,
  }) async {
    final res = await _http.post(
      _uri('/api/shop/purchase'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'offer_code': offerCode,
        'client_purchase_id': clientPurchaseId,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> shopDaily({required String clientClaimId}) async {
    final res = await _http.post(
      _uri('/api/shop/daily'),
      headers: _headers(auth: true),
      body: jsonEncode({'client_claim_id': clientClaimId}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> summonBanners() async {
    final res = await _http.get(
      _uri('/api/summon/banners'),
      headers: _headers(auth: true),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> summonPull({
    required String bannerCode,
    required String clientSummonId,
  }) async {
    final res = await _http.post(
      _uri('/api/summon/pull'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'banner_code': bannerCode,
        'client_summon_id': clientSummonId,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> pvpStatus() async {
    final res =
        await _http.get(_uri('/api/pvp/status'), headers: _headers(auth: true));
    return _decode(res);
  }

  Future<Map<String, dynamic>> pvpEnqueue({List<String>? cardCodes}) async {
    final res = await _http.post(
      _uri('/api/pvp/queue'),
      headers: _headers(auth: true),
      body: jsonEncode({
        if (cardCodes != null) 'card_codes': cardCodes,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> pvpLeaveQueue() async {
    final res = await _http.delete(
      _uri('/api/pvp/queue'),
      headers: _headers(auth: true),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> pvpAccept(int offerId) async {
    final res = await _http.post(
      _uri('/api/pvp/offers/$offerId/accept'),
      headers: _headers(auth: true),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> pvpDecline(int offerId) async {
    final res = await _http.post(
      _uri('/api/pvp/offers/$offerId/decline'),
      headers: _headers(auth: true),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> cards({String? rarity}) async {
    final res = await _http.get(
      _uri('/api/cards', {
        if (rarity != null) 'rarity': rarity,
      }),
      headers: _headers(auth: false),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> modes() async {
    final res = await _http.get(
      _uri('/api/modes'),
      headers: _headers(auth: false),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> meta() async {
    final res = await _http.get(
      _uri('/api/meta'),
      headers: _headers(auth: false),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> ready() async {
    final res = await _http.get(
      _uri('/api/ready'),
      headers: _headers(auth: false),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> collection() async {
    final res =
        await _http.get(_uri('/api/collection'), headers: _headers(auth: true));
    return _decode(res);
  }

  Future<Map<String, dynamic>> exchangeChests() async {
    final res = await _http.get(
      _uri('/api/exchange/chests'),
      headers: _headers(auth: true),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> buyKey({
    required String keyCode,
    required String clientPurchaseId,
  }) async {
    final res = await _http.post(
      _uri('/api/exchange/keys/buy'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'key_code': keyCode,
        'client_purchase_id': clientPurchaseId,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> openChest({
    required String chestCode,
    required String clientOpenId,
  }) async {
    final res = await _http.post(
      _uri('/api/exchange/chests/open'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'chest_code': chestCode,
        'client_open_id': clientOpenId,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> levelUpCard(String cardCode) async {
    final res = await _http.post(
      _uri('/api/collection/$cardCode/level-up'),
      headers: _headers(auth: true),
      body: jsonEncode({}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> teams() async {
    final res =
        await _http.get(_uri('/api/teams'), headers: _headers(auth: true));
    return _decode(res);
  }

  Future<Map<String, dynamic>> syncTeam({
    required List<String> cardCodes,
    String name = 'Main Squad',
  }) async {
    final res = await _http.post(
      _uri('/api/teams/sync'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'name': name,
        'card_codes': cardCodes,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> createMatch({
    List<String>? cardCodes,
    String mode = 'online_clash',
  }) async {
    final res = await _http.post(
      _uri('/api/matches'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'mode': mode,
        if (cardCodes != null) 'card_codes': cardCodes,
      }),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getMatch(int matchId) async {
    final res = await _http.get(
      _uri('/api/matches/$matchId'),
      headers: _headers(auth: true),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> matchAction({
    required int matchId,
    required String type,
    required String actorId,
    required String clientActionId,
    required int stateVersion,
    String? targetId,
  }) async {
    final res = await _http.post(
      _uri('/api/matches/$matchId/actions'),
      headers: _headers(auth: true),
      body: jsonEncode({
        'type': type,
        'actor_id': actorId,
        'target_id': targetId,
        'client_action_id': clientActionId,
        'state_version': stateVersion,
      }),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Unexpected response shape.',
        statusCode: res.statusCode,
      );
    }
    if (res.statusCode >= 400) {
      final err = decoded['error'] as Map<String, dynamic>?;
      throw ApiException(
        code: err?['code'] as String? ?? 'HTTP_ERROR',
        message: err?['message'] as String? ?? 'Request failed.',
        statusCode: res.statusCode,
        details: err?['details'] as Map<String, dynamic>? ?? const {},
        retryable: err?['retryable'] as bool? ?? false,
      );
    }
    return decoded;
  }
}

class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.details = const {},
    this.retryable = false,
  });

  final String code;
  final String message;
  final int statusCode;
  final Map<String, dynamic> details;
  final bool retryable;

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
