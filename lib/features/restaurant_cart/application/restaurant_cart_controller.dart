import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../restaurant_menu/domain/models/food_item_model.dart';
import '../data/repositories/restaurant_cart_repository.dart';
import '../domain/models/restaurant_cart_line_item.dart';

final restaurantCartRepositoryProvider = Provider<RestaurantCartRepository>((ref) {
  return RestaurantCartRepository(ref.watch(dioClientProvider));
});

class RestaurantCartState {
  final String? restaurantId;
  final String? restaurantName;
  final List<RestaurantCartLineItem> items;
  final bool isLoading;

  const RestaurantCartState({this.restaurantId, this.restaurantName, this.items = const [], this.isLoading = true});

  RestaurantCartState copyWith({String? restaurantId, String? restaurantName, List<RestaurantCartLineItem>? items, bool? isLoading}) {
    return RestaurantCartState(
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);
  double get itemTotal => items.fold(0, (sum, i) => sum + i.lineTotal);
}

final restaurantCartControllerProvider = StateNotifierProvider<RestaurantCartController, RestaurantCartState>((ref) {
  return RestaurantCartController(ref.watch(restaurantCartRepositoryProvider));
});

/// Single-restaurant basket — matches Swiggy/Zomato's rule that adding an
/// item from a different restaurant prompts to clear the current cart
/// first (handled in the UI layer via [wouldConflictWithRestaurant]).
class RestaurantCartController extends StateNotifier<RestaurantCartState> {
  RestaurantCartController(this._repository) : super(const RestaurantCartState()) {
    _load();
  }
  final RestaurantCartRepository _repository;

  Future<void> _load() async {
    final loaded = await _repository.load();
    state = RestaurantCartState(restaurantId: loaded.restaurantId, items: loaded.items, isLoading: false);
  }

  Future<void> _persist() => _repository.save(state.restaurantId, state.items);

  bool wouldConflictWithRestaurant(String restaurantId) {
    return state.restaurantId != null && state.restaurantId != restaurantId && state.items.isNotEmpty;
  }

  Future<void> clearCart() async {
    state = state.copyWith(restaurantId: null, restaurantName: null, items: []);
    await _persist();
  }

  Future<void> addItem({
    required FoodItemModel food,
    required String restaurantName,
    int quantity = 1,
    List<String> addOnLabels = const [],
    double addOnsTotal = 0,
    String? instructions,
  }) async {
    final line = RestaurantCartLineItem(
      id: 'rcart-${DateTime.now().millisecondsSinceEpoch}',
      food: food,
      quantity: quantity,
      selectedAddOnLabels: addOnLabels,
      addOnsTotal: addOnsTotal,
      instructions: instructions,
    );
    state = state.copyWith(restaurantId: food.restaurantId, restaurantName: restaurantName, items: [...state.items, line]);
    await _persist();
  }

  Future<void> updateQuantity(String lineId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(lineId);
      return;
    }
    state = state.copyWith(items: state.items.map((i) => i.id == lineId ? i.copyWith(quantity: quantity) : i).toList());
    await _persist();
  }

  Future<void> removeItem(String lineId) async {
    final updated = state.items.where((i) => i.id != lineId).toList();
    state = state.copyWith(items: updated, restaurantId: updated.isEmpty ? null : state.restaurantId, restaurantName: updated.isEmpty ? null : state.restaurantName);
    await _persist();
  }
}
