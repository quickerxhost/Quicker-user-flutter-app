import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/restaurant_model.dart';

/// `ApiEndpoints.restaurantList` / `restaurantDetail` are currently BLANK —
/// falls back to fixture data that mirrors the Stitch `restaurants_quickerx`
/// design exactly (same restaurant names, cuisines, ratings, ETAs) so the
/// module is fully click-throughable and pixel-reviewable before the
/// backend exists.
class RestaurantRepository {
  RestaurantRepository(this._client);
  final DioClient _client;

  Future<ApiResult<List<RestaurantModel>>> getRestaurants({int page = 1, int pageSize = 10}) async {
    if (ApiEndpoints.restaurantList.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 450));
      final all = _fixtureList();
      final start = (page - 1) * pageSize;
      if (start >= all.length) return const ApiResult.success([]);
      final end = (start + pageSize).clamp(0, all.length);
      return ApiResult.success(all.sublist(start, end));
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.restaurantList, queryParameters: {'page': page, 'page_size': pageSize});
        return (response.data as List).cast<Map<String, dynamic>>();
      });
      return ApiResult.success(data.map(RestaurantModel.fromJson).toList());
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<RestaurantModel>> getRestaurantDetail(String id) async {
    if (ApiEndpoints.restaurantDetail.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      final match = _fixtureList().where((r) => r.id == id).toList();
      return ApiResult.success(match.isNotEmpty ? match.first : _fixtureList().first);
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get('${ApiEndpoints.restaurantDetail}/$id');
        return response.data as Map<String, dynamic>;
      });
      return ApiResult.success(RestaurantModel.fromJson(data));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  List<RestaurantModel> _fixtureList() => const [
        RestaurantModel(
          id: 'the-spice-hub',
          name: 'The Spice Hub',
          imageUrl: '',
          cuisineTags: 'North Indian • Biryani • Mughlai',
          rating: 4.8,
          reviewCount: 1200,
          distanceKm: 1.5,
          etaMinutes: 25,
          costForTwo: 250,
          purity: FoodPurity.pureVeg,
          openingHours: '11:00 AM - 11:00 PM',
          licenseFssai: '11224011000456',
          address: '12/B Art District, Midtown',
        ),
        RestaurantModel(
          id: 'bella-cucina',
          name: 'Bella Cucina',
          imageUrl: '',
          cuisineTags: 'Italian • Pizza • Pasta',
          rating: 4.5,
          reviewCount: 860,
          distanceKm: 2.8,
          etaMinutes: 32,
          costForTwo: 800,
          purity: FoodPurity.nonVeg,
          address: '4th Cross, Riverside Road',
        ),
        RestaurantModel(
          id: 'burger-beast',
          name: 'Burger Beast',
          imageUrl: '',
          cuisineTags: 'Fast Food • American • Beverages',
          rating: 4.2,
          reviewCount: 640,
          distanceKm: 0.9,
          etaMinutes: 20,
          costForTwo: 400,
          isBestseller: true,
          address: 'Shop 3, Central Market',
        ),
        RestaurantModel(
          id: 'morning-glory-cafe',
          name: 'Morning Glory Cafe',
          imageUrl: '',
          cuisineTags: 'Breakfast • Healthy • Juices',
          rating: 4.6,
          reviewCount: 210,
          distanceKm: 1.2,
          etaMinutes: 22,
          costForTwo: 350,
          isNew: true,
          freeDelivery: true,
          address: '22 Garden View Lane',
        ),
        RestaurantModel(
          id: 'zenko-sushi',
          name: 'Zenko Sushi',
          imageUrl: '',
          cuisineTags: 'Japanese • Seafood • Asian',
          rating: 4.7,
          reviewCount: 430,
          distanceKm: 3.4,
          etaMinutes: 35,
          costForTwo: 900,
          address: '9 Harbor Walk',
        ),
      ];
}
