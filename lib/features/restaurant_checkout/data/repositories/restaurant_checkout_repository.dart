import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../restaurant_orders/domain/models/restaurant_order_model.dart';
import '../../domain/models/restaurant_delivery_slot_model.dart';

/// `ApiEndpoints.restaurantCheckout` / `placeOrder` are currently BLANK —
/// mirrors the pattern established in the Shopping Experience's
/// `CheckoutRepository`, kept as its own independent class so the
/// Restaurant module doesn't depend on (or risk changing) Phase 2 code.
class RestaurantCheckoutRepository {
  RestaurantCheckoutRepository(this._client);
  final DioClient _client;

  Future<ApiResult<List<RestaurantDeliverySlotModel>>> getDeliverySlots() async {
    if (ApiEndpoints.deliverySlots.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      final now = DateTime.now();
      return ApiResult.success([
        const RestaurantDeliverySlotModel(id: 'instant', type: RestaurantDeliverySlotType.instant, label: 'Instant Delivery (25-30 mins)'),
        RestaurantDeliverySlotModel(
          id: 'slot-1',
          type: RestaurantDeliverySlotType.scheduled,
          label: 'Today, 8:00 PM - 8:30 PM',
          windowStart: DateTime(now.year, now.month, now.day, 20),
        ),
      ]);
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.deliverySlots);
        return (response.data as List).cast<Map<String, dynamic>>();
      });
      return ApiResult.success(data
          .map((e) => RestaurantDeliverySlotModel(
                id: e['id'].toString(),
                type: RestaurantDeliverySlotType.values.byName(e['type'] as String),
                label: e['label'] as String,
              ))
          .toList());
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<RestaurantOrderModel>> placeOrder({
    required String restaurantId,
    required String restaurantName,
    required int itemCount,
    required double grandTotal,
    required String deliveryAddressLine,
    required String paymentMethodLabel,
  }) async {
    if (ApiEndpoints.placeOrder.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 700));
      final orderId = 'QX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      return ApiResult.success(RestaurantOrderModel(
        orderId: orderId,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        restaurantImageUrl: '',
        restaurantAddress: '12/B Art District, Midtown',
        restaurantPhone: '+91 98765 43210',
        placedAt: DateTime.now(),
        status: RestaurantOrderStatus.placed,
        itemCount: itemCount,
        grandTotal: grandTotal,
        etaLabel: '25-30 mins',
        deliveryAddressLine: deliveryAddressLine,
        paymentMethodLabel: paymentMethodLabel,
      ));
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.post(ApiEndpoints.placeOrder, data: {
          'restaurant_id': restaurantId,
          'grand_total': grandTotal,
          'delivery_address_line': deliveryAddressLine,
          'payment_method_label': paymentMethodLabel,
        });
        return response.data as Map<String, dynamic>;
      });
      return ApiResult.success(RestaurantOrderModel.fromJson(data));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }
}
