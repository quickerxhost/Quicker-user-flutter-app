import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../restaurant_menu/domain/models/food_item_model.dart';
import '../../restaurants/data/repositories/restaurant_repository.dart';
import '../../restaurants/domain/models/restaurant_model.dart';

/// `ApiEndpoints.restaurantSearch` is currently BLANK — filters the same
/// fixture restaurant list used by [RestaurantRepository] and a small food
/// fixture set client-side, so typing feels real before the backend exists.
class RestaurantSearchRepository {
  RestaurantSearchRepository(this._client, this._restaurantRepository);
  final DioClient _client;
  final RestaurantRepository _restaurantRepository;

  static const _recent = ['Biryani', 'The Spice Hub', 'Pizza'];
  static const _trending = ['Paneer Tikka', 'Burgers', 'Sushi', 'Momos'];

  List<String> get recentSearches => _recent;
  List<String> get trendingSearches => _trending;

  Future<ApiResult<({List<RestaurantModel> restaurants, List<FoodItemModel> foods})>> search(String query) async {
    if (ApiEndpoints.restaurantSearch.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      final restaurantsResult = await _restaurantRepository.getRestaurants(pageSize: 20);
      final restaurants = restaurantsResult.when(success: (v) => v, failure: (_) => <RestaurantModel>[]);
      final matchedRestaurants = query.isEmpty
          ? restaurants
          : restaurants.where((r) => r.name.toLowerCase().contains(query.toLowerCase()) || r.cuisineTags.toLowerCase().contains(query.toLowerCase())).toList();

      const foods = <FoodItemModel>[
        FoodItemModel(id: 'paneer-tikka', restaurantId: 'the-spice-hub', name: 'Classic Paneer Tikka', description: 'Grilled cottage cheese cubes.', price: 349, imageUrl: '', purity: FoodPurity.veg),
        FoodItemModel(id: 'awadhi-biryani', restaurantId: 'the-spice-hub', name: 'Awadhi Mutton Biryani', description: 'Slow-cooked dum biryani.', price: 449, imageUrl: '', purity: FoodPurity.nonVeg),
      ];
      final matchedFoods = query.isEmpty ? const <FoodItemModel>[] : foods.where((f) => f.name.toLowerCase().contains(query.toLowerCase())).toList();

      return ApiResult.success((restaurants: matchedRestaurants, foods: matchedFoods));
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.restaurantSearch, queryParameters: {'q': query});
        return response.data as Map<String, dynamic>;
      });
      return ApiResult.success((
        restaurants: (data['restaurants'] as List).map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>)).toList(),
        foods: (data['foods'] as List).map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      ));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }
}
