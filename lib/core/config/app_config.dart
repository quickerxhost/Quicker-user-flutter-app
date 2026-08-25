/// Central runtime configuration.
abstract final class AppConfig {
  /// Base URL of the backend API. Defaults to this machine's LAN IP so the
  /// app works on a physical phone (same Wi-Fi network as the backend).
  /// - Android emulator: run with `--dart-define=API_BASE_URL=http://10.0.2.2:8081/api/v1`
  /// - Desktop/web:     run with `--dart-define=API_BASE_URL=http://localhost:8081/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.175.214.6:8081/api/v1',
  );

  /// Connect/receive timeouts for Dio.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Toggle verbose request/response logging (Dio interceptor).
  static const bool enableNetworkLogs = true;

  /// Google Maps API key — set via --dart-define=GOOGLE_MAPS_API_KEY=...
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
}
