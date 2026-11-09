class AuthSessionStorage {
  static String? _token;

  String? read() => _token;

  void write(String token) => _token = token;

  void clear() => _token = null;
}
