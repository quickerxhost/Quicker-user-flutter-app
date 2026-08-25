import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/repositories/restaurant_orders_repository.dart';
import '../domain/models/restaurant_order_model.dart';

final restaurantOrdersRepositoryProvider = Provider<RestaurantOrdersRepository>((ref) {
  return RestaurantOrdersRepository(ref.watch(dioClientProvider));
});

final restaurantOrdersProvider = FutureProvider<List<RestaurantOrderModel>>((ref) async {
  final result = await ref.watch(restaurantOrdersRepositoryProvider).getOrders();
  return result.when(success: (v) => v, failure: (_) => const []);
});

List<RestaurantOrderModel> filterOrdersByTab(List<RestaurantOrderModel> orders, RestaurantOrderTab tab) {
  return switch (tab) {
    RestaurantOrderTab.active => orders.where((o) => o.status != RestaurantOrderStatus.delivered && o.status != RestaurantOrderStatus.cancelled).toList(),
    RestaurantOrderTab.past => orders.where((o) => o.status == RestaurantOrderStatus.delivered).toList(),
    RestaurantOrderTab.cancelled => orders.where((o) => o.status == RestaurantOrderStatus.cancelled).toList(),
  };
}

enum RestaurantOrderTab { active, past, cancelled }

/// Live tracking stream for a given [order] — drives the Order Tracking
/// screen's timeline + rider info as the fixture status advances.
final restaurantOrderTrackingProvider = StreamProvider.family<RestaurantOrderModel, RestaurantOrderModel>((ref, order) {
  return ref.watch(restaurantOrdersRepositoryProvider).watchOrderStatus(order);
});
