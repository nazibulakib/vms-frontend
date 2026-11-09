/// Static application metadata for the Flutter Web UI.
class EnvConfig {
  EnvConfig._();

  static const String appName = 'Vehicle Management System';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
}
