import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../restaurants/application/restaurant_list_controller.dart';
import '../data/repositories/menu_repository.dart';
import '../domain/models/food_item_model.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(dioClientProvider));
});

final restaurantDetailProvider = FutureProvider.family((ref, String restaurantId) async {
  final result = await ref.watch(restaurantRepositoryProvider).getRestaurantDetail(restaurantId);
  return result.when(success: (v) => v, failure: (e) => throw e);
});

final restaurantMenuProvider = FutureProvider.family<List<MenuCategoryModel>, String>((ref, restaurantId) async {
  final result = await ref.watch(menuRepositoryProvider).getMenu(restaurantId);
  return result.when(success: (v) => v, failure: (e) => throw e);
});

/// Which menu category tab is currently active (drives the sticky tab bar
/// + scroll-to-section behavior on Restaurant Details).
final activeMenuCategoryProvider = StateProvider.family<String?, String>((ref, restaurantId) => null);

/// Live "Search Food" query within a restaurant's menu.
final menuSearchQueryProvider = StateProvider.family<String, String>((ref, restaurantId) => '');
