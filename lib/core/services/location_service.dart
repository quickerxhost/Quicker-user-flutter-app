import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationPermissionState { granted, denied, deniedForever, serviceDisabled }

/// Wraps [Geolocator]/[permission_handler] behind a small app-specific API.
/// Screens (location permission, turn-on-services, finding-location) all
/// drive off of [checkAndRequest] + [getCurrentPosition].
class LocationService {
  Future<LocationPermissionState> checkAndRequest() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermissionState.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionState.deniedForever;
    }
    if (permission == LocationPermission.denied) {
      return LocationPermissionState.denied;
    }
    return LocationPermissionState.granted;
  }

  /// Fetches the device's live position, trying hard to succeed on devices
  /// where a fresh GPS fix is slow or unavailable indoors: high-accuracy fix
  /// first, then the last cached position, then a faster network-based fix.
  Future<Position> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) return lastKnown;
      } catch (_) {
        // No cached position — fall through to a network-based fix.
      }
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    }
  }

  Future<bool> openSettings() => openAppSettings();

  Future<bool> openLocationServiceSettings() =>
      Geolocator.openLocationSettings();
}
