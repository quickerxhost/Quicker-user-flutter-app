/// Central runtime configuration.
abstract final class AppConfig {
  /// Base URL of the backend API. Defaults to Android emulator host.
  /// - Android emulator: uses 10.0.2.2 (host machine's localhost)
  /// - Physical device: run with `--dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8081/api/v1`
  /// - Desktop/web:     run with `--dart-define=API_BASE_URL=https://quicker-x-backend-1.onrender.com/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.223.123.102:8081/api/v1/',
  );

  /// Connect/receive timeouts for Dio.
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Toggle verbose request/response logging (Dio interceptor).
  static const bool enableNetworkLogs = true;

  /// Google Maps API key — set via --dart-define=GOOGLE_MAPS_API_KEY=...
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
}
