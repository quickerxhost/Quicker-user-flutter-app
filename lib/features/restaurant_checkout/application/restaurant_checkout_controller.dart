import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../address/application/address_controller.dart';
import '../../payment/application/payment_controller.dart';
import '../../payment/domain/models/payment_method_model.dart';
import '../../restaurant_cart/application/restaurant_cart_controller.dart';
import '../../restaurant_orders/domain/models/restaurant_order_model.dart';
import '../data/repositories/restaurant_checkout_repository.dart';
import '../domain/models/restaurant_delivery_slot_model.dart';

final restaurantCheckoutRepositoryProvider = Provider<RestaurantCheckoutRepository>((ref) {
  return RestaurantCheckoutRepository(ref.watch(dioClientProvider));
});

final restaurantDeliverySlotsProvider = FutureProvider<List<RestaurantDeliverySlotModel>>((ref) async {
  final result = await ref.watch(restaurantCheckoutRepositoryProvider).getDeliverySlots();
  return result.when(success: (v) => v, failure: (_) => const []);
});

final restaurantSelectedSlotIdProvider = StateProvider<String>((ref) => 'instant');
final restaurantOrderInstructionsProvider = StateProvider<String>((ref) => '');

enum RestaurantPlaceOrderStatus { idle, placing, success, error }

class RestaurantPlaceOrderState {
  final RestaurantPlaceOrderStatus status;
  final RestaurantOrderModel? order;
  final String? errorMessage;
  const RestaurantPlaceOrderState({this.status = RestaurantPlaceOrderStatus.idle, this.order, this.errorMessage});
}

final restaurantPlaceOrderControllerProvider =
    StateNotifierProvider<RestaurantPlaceOrderController, RestaurantPlaceOrderState>((ref) {
  return RestaurantPlaceOrderController(ref);
});

class RestaurantPlaceOrderController extends StateNotifier<RestaurantPlaceOrderState> {
  RestaurantPlaceOrderController(this._ref) : super(const RestaurantPlaceOrderState());
  final Ref _ref;

  Future<void> placeOrder() async {
    state = const RestaurantPlaceOrderState(status: RestaurantPlaceOrderStatus.placing);

    final cart = _ref.read(restaurantCartControllerProvider);
    if (cart.items.isEmpty || cart.restaurantId == null) {
      state = const RestaurantPlaceOrderState(status: RestaurantPlaceOrderStatus.error, errorMessage: 'Your cart is empty.');
      return;
    }

    final address = _ref.read(addressListControllerProvider.notifier).defaultAddress;
    if (address == null) {
      state = const RestaurantPlaceOrderState(status: RestaurantPlaceOrderStatus.error, errorMessage: 'Please add a delivery address.');
      return;
    }

    final paymentType = _ref.read(selectedPaymentMethodProvider);
    final paymentLabel = kPaymentMethodOptions.firstWhere((o) => o.type == paymentType).label;

    final itemTotal = cart.itemTotal;
    const deliveryCharge = 40.0;
    const packingCharge = 20.0;
    final grandTotal = itemTotal + deliveryCharge + packingCharge;

    final repository = _ref.read(restaurantCheckoutRepositoryProvider);
    final result = await repository.placeOrder(
      restaurantId: cart.restaurantId!,
      restaurantName: cart.restaurantName ?? 'Restaurant',
      itemCount: cart.totalItemCount,
      grandTotal: grandTotal,
      deliveryAddressLine: address.fullLine,
      paymentMethodLabel: paymentLabel,
    );

    result.when(
      success: (order) async {
        state = RestaurantPlaceOrderState(status: RestaurantPlaceOrderStatus.success, order: order);
        await _ref.read(restaurantCartControllerProvider.notifier).clearCart();
      },
      failure: (e) => state = RestaurantPlaceOrderState(status: RestaurantPlaceOrderStatus.error, errorMessage: e.message),
    );
  }
}
