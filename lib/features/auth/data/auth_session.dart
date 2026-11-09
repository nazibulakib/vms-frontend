class AuthSession {
  const AuthSession({required this.email});

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      AuthSession(email: json['email'] as String);

  final String email;
}

class LoginResponse {
  const LoginResponse({required this.accessToken, required this.email});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    accessToken: json['accessToken'] as String,
    email: json['email'] as String,
  );

  final String accessToken;
  final String email;
}
