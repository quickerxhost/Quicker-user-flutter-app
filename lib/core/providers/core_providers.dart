import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/location_service.dart';
import '../storage/secure_storage_service.dart';

/// -------- Infrastructure singletons --------

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(secureStorageProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Emits true/false connectivity status; UI (no-internet banners/screens)
/// listens to this rather than polling.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
});