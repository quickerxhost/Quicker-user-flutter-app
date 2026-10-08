import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] so the rest of the app never
/// touches the package directly (easy to swap/mock in tests).
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyDeliveryHubId = 'delivery_hub_id';
  static const _keyDeliveryHubName = 'delivery_hub_name';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _keyAccessToken, value: token);

  Future<String?> get accessToken => _storage.read(key: _keyAccessToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _keyRefreshToken, value: token);

  Future<String?> get refreshToken => _storage.read(key: _keyRefreshToken);

  Future<void> saveDeliveryHubId(String hubId) =>
      _storage.write(key: _keyDeliveryHubId, value: hubId);

  Future<String?> get deliveryHubId => _storage.read(key: _keyDeliveryHubId);

  Future<void> saveDeliveryHubName(String hubName) =>
      _storage.write(key: _keyDeliveryHubName, value: hubName);

  Future<String?> get deliveryHubName => _storage.read(key: _keyDeliveryHubName);

  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
