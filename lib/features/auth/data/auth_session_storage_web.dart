import 'package:web/web.dart' as web;

class AuthSessionStorage {
  static const _accessTokenKey = 'vms_access_token';

  String? read() => web.window.sessionStorage.getItem(_accessTokenKey);

  void write(String token) =>
      web.window.sessionStorage.setItem(_accessTokenKey, token);

  void clear() => web.window.sessionStorage.removeItem(_accessTokenKey);
}
