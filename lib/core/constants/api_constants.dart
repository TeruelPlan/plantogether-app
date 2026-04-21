class ApiConstants {
  // Dev default: Traefik on localhost:80
  // Android emulator: --dart-define=API_BASE_URL=http://10.0.2.2
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost',
  );

  static const wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'http://localhost',
  );

  static const deviceIdHeader = 'X-Device-Id';
}
