import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/repositories/restaurant_repository.dart';
import '../domain/models/restaurant_model.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(ref.watch(dioClientProvider));
});

enum RestaurantSort { relevance, ratingHighToLow, deliveryTime, costLowToHigh }

class RestaurantListState {
  final List<RestaurantModel> restaurants;
  final int page;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final RestaurantSort sort;
  final bool fastDeliveryOnly;
  final bool pureVegOnly;

  const RestaurantListState({
    this.restaurants = const [],
    this.page = 1,
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.sort = RestaurantSort.relevance,
    this.fastDeliveryOnly = false,
    this.pureVegOnly = false,
  });

  List<RestaurantModel> get filteredSorted {
    var list = restaurants.where((r) {
      if (fastDeliveryOnly && r.etaMinutes > 25) return false;
      if (pureVegOnly && r.purity != FoodPurity.pureVeg) return false;
      return true;
    }).toList();
    switch (sort) {
      case RestaurantSort.ratingHighToLow:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case RestaurantSort.deliveryTime:
        list.sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
      case RestaurantSort.costLowToHigh:
        list.sort((a, b) => a.costForTwo.compareTo(b.costForTwo));
      case RestaurantSort.relevance:
        break;
    }
    return list;
  }

  RestaurantListState copyWith({
    List<RestaurantModel>? restaurants,
    int? page,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    RestaurantSort? sort,
    bool? fastDeliveryOnly,
    bool? pureVegOnly,
  }) {
    return RestaurantListState(
      restaurants: restaurants ?? this.restaurants,
      page: page ?? this.page,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      sort: sort ?? this.sort,
      fastDeliveryOnly: fastDeliveryOnly ?? this.fastDeliveryOnly,
      pureVegOnly: pureVegOnly ?? this.pureVegOnly,
    );
  }
}

final restaurantListControllerProvider =
    StateNotifierProvider<RestaurantListController, RestaurantListState>((ref) {
  return RestaurantListController(ref.watch(restaurantRepositoryProvider));
});

class RestaurantListController extends StateNotifier<RestaurantListState> {
  RestaurantListController(this._repository) : super(const RestaurantListState()) {
    loadFirstPage();
  }
  final RestaurantRepository _repository;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isInitialLoading: true, errorMessage: null, page: 1);
    final result = await _repository.getRestaurants(page: 1);
    result.when(
      success: (list) => state = state.copyWith(restaurants: list, isInitialLoading: false, hasMore: list.isNotEmpty, page: 1),
      failure: (e) => state = state.copyWith(isInitialLoading: false, errorMessage: e.message),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;
    final result = await _repository.getRestaurants(page: nextPage);
    result.when(
      success: (list) => state = state.copyWith(
        restaurants: [...state.restaurants, ...list],
        isLoadingMore: false,
        hasMore: list.isNotEmpty,
        page: nextPage,
      ),
      failure: (e) => state = state.copyWith(isLoadingMore: false, errorMessage: e.message),
    );
  }

  void setSort(RestaurantSort sort) => state = state.copyWith(sort: sort);
  void toggleFastDelivery(bool value) => state = state.copyWith(fastDeliveryOnly: value);
  void togglePureVeg(bool value) => state = state.copyWith(pureVegOnly: value);
}
