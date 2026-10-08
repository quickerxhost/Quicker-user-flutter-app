import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../address/application/address_controller.dart';
import '../../cart/application/cart_controller.dart';
import '../../coupons/application/coupon_controller.dart';
import '../../payment/application/payment_controller.dart';
import '../../payment/domain/models/payment_method_model.dart';
import '../data/repositories/checkout_repository.dart';
import '../domain/models/order_model.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.watch(dioClientProvider));
});

final deliverySlotsProvider = FutureProvider<List<DeliverySlotModel>>((ref) async {
  final result = await ref.watch(checkoutRepositoryProvider).getDeliverySlots();
  return result.when(success: (v) => v, failure: (_) => const []);
});

final selectedDeliverySlotIdProvider = StateProvider<String>((ref) => 'instant');
final orderNotesProvider = StateProvider<String>((ref) => '');

enum PlaceOrderStatus { idle, placing, success, error }

class PlaceOrderState {
  final PlaceOrderStatus status;
  final OrderModel? order;
  final String? errorMessage;
  const PlaceOrderState({this.status = PlaceOrderStatus.idle, this.order, this.errorMessage});
}

final placeOrderControllerProvider = StateNotifierProvider<PlaceOrderController, PlaceOrderState>((ref) {
  return PlaceOrderController(ref);
});

class PlaceOrderController extends StateNotifier<PlaceOrderState> {
  PlaceOrderController(this._ref) : super(const PlaceOrderState());
  final Ref _ref;

  Future<void> placeOrder() async {
    state = const PlaceOrderState(status: PlaceOrderStatus.placing);

    final address = _ref.read(addressListControllerProvider.notifier).defaultAddress;
    if (address == null) {
      state = const PlaceOrderState(status: PlaceOrderStatus.error, errorMessage: 'Please add a delivery address.');
      return;
    }

    final summary = _ref.read(cartPriceSummaryProvider);
    final coupon = _ref.read(appliedCouponProvider);
    final couponDiscount = coupon?.discountFor(summary.subtotal) ?? 0;
    final grandTotal = summary.grandTotal - couponDiscount;

    final slotId = _ref.read(selectedDeliverySlotIdProvider);
    final etaLabel = slotId == 'instant' ? '18 Mins' : 'Scheduled';
    final paymentType = _ref.read(selectedPaymentMethodProvider);
    final paymentLabel = kPaymentMethodOptions.firstWhere((o) => o.type == paymentType).label;

    final repository = _ref.read(checkoutRepositoryProvider);
    final result = await repository.placeOrder(
      grandTotal: grandTotal,
      deliveryAddressLine: address.fullLine,
      paymentMethodLabel: paymentLabel,
      etaLabel: etaLabel,
      notes: _ref.read(orderNotesProvider),
    );

    result.when(
      success: (order) async {
        state = PlaceOrderState(status: PlaceOrderStatus.success, order: order);
        await _ref.read(cartControllerProvider.notifier).clearCart();
        _ref.read(appliedCouponProvider.notifier).state = null;
      },
      failure: (e) => state = PlaceOrderState(status: PlaceOrderStatus.error, errorMessage: e.message),
    );
  }

  void reset() => state = const PlaceOrderState();
}
