import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/api_url_resolver.dart';
import '../../domain/models/banner_model.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/delivery_hub_model.dart';
import '../../domain/models/home_feed_model.dart';
import '../../domain/models/product_model.dart';

/// Live customer home feed backed by the QuickerX backend:
/// 1. requests the device's live location,
/// 2. resolves the delivery hub whose radius contains it
///    (`GET /public/catalog/hub`),
/// 3. loads that hub's full master catalog (`GET /public/catalog/products`).
///
/// Outside every hub's delivery radius the feed still succeeds with an empty
/// product list and a "no hub" marker so the screen degrades gracefully.
/// Categories and banners have no backend endpoint yet, so those stay on the
/// fixture set; the product grid is 100% live.
class HomeRepository {
  HomeRepository(this._client, this._locationService, this._secureStorage);

  final DioClient _client;
  final LocationService _locationService;
  final SecureStorageService _secureStorage;

  Future<ApiResult<HomeFeedModel>> getHomeFeed() async {
    try {
      // Location is best-effort: when it's missing/denied the backend serves
      // the default hub's catalog, so the feed must never block on it.
      Position? position;
      try {
        final permission = await _locationService.checkAndRequest();
        if (permission == LocationPermissionState.granted) {
          position = await _locationService.getCurrentPosition();
        }
      } catch (_) {
        position = null;
      }
      final lat = position?.latitude;
      final lng = position?.longitude;

      // The three feeds run in parallel but degrade independently: a slow or
      // failed hub/categories call never discards the already-loaded master
      // catalog. The products call stays authoritative — when the catalog
      // itself fails the whole feed surfaces the error instead of blanking.
      final hubFuture = _client
          .guard((dio) async {
            final response = await dio.get(
              ApiEndpoints.publicHub,
              queryParameters:
                  lat == null || lng == null ? null : {'lat': lat, 'lng': lng},
            );
            return response.data as Map<String, dynamic>?;
          })
          .catchError((Object _) => null);

      final categoryFuture = _client
          .guard((dio) async {
            final response = await dio.get(
              ApiEndpoints.publicCategories,
              queryParameters:
                  lat == null || lng == null ? null : {'lat': lat, 'lng': lng},
            );
            return (response.data as List? ?? []).cast<Map<String, dynamic>>();
          })
          .catchError((Object _) => <Map<String, dynamic>>[]);

      final productFuture = _client.guard((dio) async {
        final response = await dio.get(
          ApiEndpoints.publicProducts,
          queryParameters:
              lat == null || lng == null ? null : {'lat': lat, 'lng': lng},
        );
        return (response.data as List? ?? []).cast<Map<String, dynamic>>();
      });

      final hubJson = await hubFuture;
      final categoryList = await categoryFuture;
      final productList = await productFuture;

      final hub = hubJson == null
          ? const DeliveryHubModel(
              id: '',
              name: 'Outside delivery area',
              etaMinutes: 0,
              shopCount: 0,
            )
          : DeliveryHubModel(
              id: hubJson['id'].toString(),
              name: hubJson['name'] as String? ?? 'QuickerX Hub',
              etaMinutes: (hubJson['etaMinutes'] as num?)?.toInt() ?? 0,
              shopCount: (hubJson['shopCount'] as num?)?.toInt() ?? 0,
              latitude: (hubJson['latitude'] as num?)?.toDouble(),
              longitude: (hubJson['longitude'] as num?)?.toDouble(),
            );

      if (hubJson != null) {
        await _secureStorage.saveDeliveryHubId(hub.id);
        await _secureStorage.saveDeliveryHubName(hub.name);
      }

      final categories = categoryList.isEmpty
          ? _fixtureCategories
          : categoryList
              .map((c) => CategoryModel(
                    id: c['id'].toString(),
                    name: c['name'] as String? ?? '',
                    icon: Icons.category_outlined,
                  ))
              .toList();

      return ApiResult.success(HomeFeedModel(
        greetingName: 'there',
        hub: hub,
        categories: categories,
        banners: _fixtureBanners,
        trendingProducts: productList.map(_productFromJson).toList(),
      ));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (_) {
      return const ApiResult.failure(NetworkException(
        type: NetworkFailureType.unknown,
        message: 'Could not load your location. Please try again.',
      ));
    }
  }

  ProductModel _productFromJson(Map<String, dynamic> json) {
    final mrp = (json['mrp'] as num?)?.toDouble();
    final sellingPrice = (json['sellingPrice'] as num?)?.toDouble() ?? 0;
    final packSize = json['packSize'] as String? ?? '';
    final unit = json['unit'] as String? ?? '';
    final metaParts = [packSize, unit].where((s) => s.isNotEmpty).join(' · ');

    return ProductModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      imageUrl: resolveApiUrl(json['imageUrl'] as String? ?? ''),
      price: sellingPrice,
      originalPrice: (mrp != null && mrp > sellingPrice) ? mrp : null,
      meta: metaParts.isNotEmpty
          ? metaParts
          : (json['brandName'] as String? ?? '') == ''
              ? null
              : json['brandName'] as String?,
      isWishlisted: false,
      inStock: json['inStock'] as bool? ?? true,
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName'] as String?,
    );
  }

  /// Absolute (Cloudinary etc.) URLs pass through; backend-relative
  /// `/uploads/...` paths are resolved against the API origin — see
  /// [resolveApiUrl].
  static const List<CategoryModel> _fixtureCategories = [
    CategoryModel(id: 'grocery', name: 'Grocery', icon: Icons.local_grocery_store_outlined),
    CategoryModel(id: 'bakery', name: 'Bakery', icon: Icons.bakery_dining_outlined),
    CategoryModel(id: 'dairy', name: 'Dairy', icon: Icons.egg_alt_outlined),
    CategoryModel(id: 'veg_fruits', name: 'Vegetables & Fruits', icon: Icons.eco_outlined),
    CategoryModel(id: 'stationery', name: 'Stationery', icon: Icons.edit_note_outlined),
    CategoryModel(id: 'fashion', name: 'Fashion', icon: Icons.checkroom_outlined),
    CategoryModel(id: 'footwear', name: 'Footwear', icon: Icons.roller_skating_outlined),
    CategoryModel(id: 'electronics', name: 'Electronics', icon: Icons.devices_outlined),
    CategoryModel(id: 'hardware', name: 'Hardware', icon: Icons.build_outlined),
  ];

  static const List<BannerModel> _fixtureBanners = [
    BannerModel(
      id: 'banner-food',
      title: 'Food Delivery',
      subtitle: 'Order from your favourite restaurants with express speed.',
      imageUrl: '',
    ),
    BannerModel(
      id: 'banner-festival',
      title: 'Festival Delights',
      subtitle: 'Flat 50% OFF on all sweets',
      code: 'FEST50',
      imageUrl: '',
    ),
  ];
}
