import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/address_model.dart';

/// `ApiEndpoints.addresses` / `addAddress` / `updateAddress` /
/// `deleteAddress` / `reverseGeocode` are BLANK because the backend has no
/// address module yet — addresses are persisted locally
/// (SharedPreferences) until that lands.
class AddressRepository {
  AddressRepository(this._client);
  // ignore: unused_field
  final DioClient _client;

  static const _key = 'addresses_v1';

  Future<List<AddressModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(AddressModel.fromJson).toList();
  }

  Future<void> saveAll(List<AddressModel> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(addresses.map((a) => a.toJson()).toList()));
    // NOTE: the backend has no /addresses module yet — when it lands, sync
    // the diff here (POST/PATCH/DELETE per changed address).
  }

  /// Reverse-geocodes a lat/lng into an address. `ApiEndpoints.reverseGeocode`
  /// is blank, so this returns a clearly-labeled placeholder the user can
  /// edit — swap for a real Google Geocoding call once the endpoint exists.
  Future<AddressModel> reverseGeocode({required double latitude, required double longitude}) async {
    if (ApiEndpoints.reverseGeocode.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 400));
      return AddressModel(
        id: 'gps-${DateTime.now().millisecondsSinceEpoch}',
        houseNumber: '',
        building: '',
        area: 'Detected location (edit to confirm)',
        city: '',
        state: '',
        pinCode: '',
        latitude: latitude,
        longitude: longitude,
      );
    }
    final data = await _client.guard((dio) async {
      final response = await dio.get(ApiEndpoints.reverseGeocode, queryParameters: {'lat': latitude, 'lng': longitude});
      return response.data as Map<String, dynamic>;
    });
    return AddressModel.fromJson(data);
  }
}
