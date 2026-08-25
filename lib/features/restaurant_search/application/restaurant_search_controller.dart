import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../restaurant_menu/domain/models/food_item_model.dart';
import '../../restaurants/application/restaurant_list_controller.dart';
import '../../restaurants/domain/models/restaurant_model.dart';
import '../data/restaurant_search_repository.dart' show RestaurantSearchRepository;

final restaurantSearchRepositoryProvider = Provider<RestaurantSearchRepository>((ref) {
  return RestaurantSearchRepository(ref.watch(dioClientProvider), ref.watch(restaurantRepositoryProvider));
});

class RestaurantSearchState {
  final String query;
  final bool isLoading;
  final List<RestaurantModel> restaurantResults;
  final List<FoodItemModel> foodResults;
  final String? errorMessage;

  const RestaurantSearchState({
    this.query = '',
    this.isLoading = false,
    this.restaurantResults = const [],
    this.foodResults = const [],
    this.errorMessage,
  });

  RestaurantSearchState copyWith({
    String? query,
    bool? isLoading,
    List<RestaurantModel>? restaurantResults,
    List<FoodItemModel>? foodResults,
    String? errorMessage,
  }) {
    return RestaurantSearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      restaurantResults: restaurantResults ?? this.restaurantResults,
      foodResults: foodResults ?? this.foodResults,
      errorMessage: errorMessage,
    );
  }
}

final restaurantSearchControllerProvider =
    StateNotifierProvider<RestaurantSearchController, RestaurantSearchState>((ref) {
  return RestaurantSearchController(ref.watch(restaurantSearchRepositoryProvider));
});

class RestaurantSearchController extends StateNotifier<RestaurantSearchState> {
  RestaurantSearchController(this._repository) : super(const RestaurantSearchState());
  final RestaurantSearchRepository _repository;

  List<String> get recentSearches => _repository.recentSearches;
  List<String> get trendingSearches => _repository.trendingSearches;

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true, errorMessage: null);
    final result = await _repository.search(query);
    result.when(
      success: (data) => state = state.copyWith(isLoading: false, restaurantResults: data.restaurants, foodResults: data.foods),
      failure: (e) => state = state.copyWith(isLoading: false, errorMessage: e.message),
    );
  }

  void clear() => state = const RestaurantSearchState();
}
