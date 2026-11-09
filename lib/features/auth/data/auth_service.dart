import 'package:vms_frontend/features/auth/data/auth_api_client.dart';
import 'package:vms_frontend/features/auth/data/auth_session.dart';
import 'package:vms_frontend/features/auth/data/auth_session_store.dart';

class AuthService {
  AuthService._()
    : _apiClient = AuthApiClient(),
      _sessionStore = AuthSessionStore();

  static final AuthService instance = AuthService._();

  final AuthApiClient _apiClient;
  final AuthSessionStore _sessionStore;

  String? get accessToken => _sessionStore.readAccessToken();

  Future<AuthSession?> restoreSession() async {
    final token = accessToken;
    if (token == null || token.isEmpty) return null;
    try {
      return await _apiClient.currentSession(token);
    } catch (_) {
      _sessionStore.clear();
      return null;
    }
  }

  Future<AuthSession> login(String email, String password) async {
    final response = await _apiClient.login(email.trim(), password);
    _sessionStore.writeAccessToken(response.accessToken);
    return AuthSession(email: response.email);
  }

  Future<void> logout() async {
    final token = accessToken;
    try {
      if (token != null && token.isNotEmpty) {
        await _apiClient.logout(token);
      }
    } finally {
      _sessionStore.clear();
    }
  }

  void clearSession() => _sessionStore.clear();
}
