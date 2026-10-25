import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_client.dart';

const kDefaultApiBaseUrl = String.fromEnvironment(
  'BCS_API_BASE',
  defaultValue: 'http://10.0.2.2:8000',
);

class SessionState {
  const SessionState({
    this.token,
    this.userName,
    this.userEmail,
    this.busy = false,
    this.error,
  });

  final String? token;
  final String? userName;
  final String? userEmail;
  final bool busy;
  final String? error;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  SessionState copyWith({
    String? token,
    String? userName,
    String? userEmail,
    bool? busy,
    String? error,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return SessionState(
      token: clearSession ? null : (token ?? this.token),
      userName: clearSession ? null : (userName ?? this.userName),
      userEmail: clearSession ? null : (userEmail ?? this.userEmail),
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SessionController extends AsyncNotifier<SessionState> {
  static const _tokenKey = 'bcs_api_token';
  static const _nameKey = 'bcs_api_name';
  static const _emailKey = 'bcs_api_email';

  late ApiClient _client;

  ApiClient get client => _client;

  @override
  Future<SessionState> build() async {
    _client = ApiClient(baseUrl: kDefaultApiBaseUrl);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return const SessionState();
    }
    _client.accessToken = token;
    return SessionState(
      token: token,
      userName: prefs.getString(_nameKey),
      userEmail: prefs.getString(_emailKey),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = AsyncData((state.value ?? const SessionState()).copyWith(busy: true, clearError: true));
    try {
      final body = await _client.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: password,
      );
      await _persist(body);
    } on ApiException catch (e) {
      state = AsyncData((state.value ?? const SessionState()).copyWith(
        busy: false,
        error: e.message,
      ));
    } catch (_) {
      state = AsyncData((state.value ?? const SessionState()).copyWith(
        busy: false,
        error: 'Cannot reach API at $kDefaultApiBaseUrl',
      ));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = AsyncData((state.value ?? const SessionState()).copyWith(busy: true, clearError: true));
    try {
      final body = await _client.login(email: email, password: password);
      await _persist(body);
    } on ApiException catch (e) {
      state = AsyncData((state.value ?? const SessionState()).copyWith(
        busy: false,
        error: e.message,
      ));
    } catch (_) {
      state = AsyncData((state.value ?? const SessionState()).copyWith(
        busy: false,
        error: 'Cannot reach API at $kDefaultApiBaseUrl',
      ));
    }
  }

  Future<void> logout() async {
    try {
      await _client.logout();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    state = const AsyncData(SessionState());
  }

  Future<void> _persist(Map<String, dynamic> body) async {
    final token = body['token'] as String?;
    final user = body['user'] as Map<String, dynamic>? ?? {};
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    }
    await prefs.setString(_nameKey, user['name'] as String? ?? '');
    await prefs.setString(_emailKey, user['email'] as String? ?? '');
    state = AsyncData(
      SessionState(
        token: token,
        userName: user['name'] as String?,
        userEmail: user['email'] as String?,
        busy: false,
      ),
    );
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionController, SessionState>(SessionController.new);
