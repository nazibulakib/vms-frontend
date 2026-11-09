import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vms_frontend/core/config/env_config.dart';
import 'package:vms_frontend/features/auth/data/auth_api_exception.dart';
import 'package:vms_frontend/features/auth/data/auth_session.dart';

class AuthApiClient {
  AuthApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? EnvConfig.apiBaseUrl).replaceFirst(
        RegExp(r'/+$'),
        '',
      );

  final http.Client _client;
  final String _baseUrl;

  Future<LoginResponse> login(String email, String password) async {
    final response = await _send(
      () => _client.post(
        _uri('/auth/login'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    final json = _readJson(response);
    if (json is! Map<String, dynamic>) {
      throw const AuthApiException(
        'The server returned an invalid login response.',
      );
    }
    return LoginResponse.fromJson(json);
  }

  Future<AuthSession> currentSession(String accessToken) async {
    final response = await _send(
      () => _client.get(
        _uri('/auth/session'),
        headers: _bearerHeaders(accessToken),
      ),
    );
    final json = _readJson(response);
    if (json is! Map<String, dynamic>) {
      throw const AuthApiException(
        'The server returned an invalid session response.',
      );
    }
    return AuthSession.fromJson(json);
  }

  Future<void> logout(String accessToken) async {
    final response = await _send(
      () => _client.post(
        _uri('/auth/logout'),
        headers: _bearerHeaders(accessToken),
      ),
    );
    if (response.statusCode != 204) {
      throw AuthApiException(
        'Sign out could not be completed.',
        statusCode: response.statusCode,
      );
    }
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _bearerHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = _readJson(response);
        final message =
            body is Map<String, dynamic> && body['message'] is String
            ? body['message'] as String
            : 'Authentication request failed (${response.statusCode}).';
        throw AuthApiException(message, statusCode: response.statusCode);
      }
      return response;
    } on AuthApiException {
      rethrow;
    } on TimeoutException {
      throw const AuthApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'Could not connect to the server. Check your connection and try again.',
      );
    } on FormatException {
      throw const AuthApiException('The server returned an invalid response.');
    }
  }

  dynamic _readJson(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
