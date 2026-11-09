import 'auth_session_storage_stub.dart'
    if (dart.library.js_interop) 'auth_session_storage_web.dart'
    as storage;

class AuthSessionStore {
  final storage.AuthSessionStorage _storage = storage.AuthSessionStorage();

  String? readAccessToken() => _storage.read();

  void writeAccessToken(String token) => _storage.write(token);

  void clear() => _storage.clear();
}
