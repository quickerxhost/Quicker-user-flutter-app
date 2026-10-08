import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/order_model.dart';

/// `ApiEndpoints.deliverySlots` / `placeOrder` are currently BLANK —
/// [getDeliverySlots] returns a fixture instant + scheduled set, and
/// [placeOrder] returns a locally-generated order confirmation so the whole
/// checkout -> success flow is testable end-to-end today.
class CheckoutRepository {
  CheckoutRepository(this._client);
  final DioClient _client;

  Future<ApiResult<List<DeliverySlotModel>>> getDeliverySlots() async {
    if (ApiEndpoints.deliverySlots.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      final now = DateTime.now();
      return ApiResult.success([
        const DeliverySlotModel(id: 'instant', type: DeliverySlotType.instant, label: 'Instant Delivery (18 mins)'),
        DeliverySlotModel(
          id: 'slot-1',
          type: DeliverySlotType.scheduled,
          label: 'Today, 6:00 PM - 7:00 PM',
          windowStart: DateTime(now.year, now.month, now.day, 18),
          windowEnd: DateTime(now.year, now.month, now.day, 19),
        ),
        DeliverySlotModel(
          id: 'slot-2',
          type: DeliverySlotType.scheduled,
          label: 'Tomorrow, 9:00 AM - 10:00 AM',
          windowStart: DateTime(now.year, now.month, now.day + 1, 9),
          windowEnd: DateTime(now.year, now.month, now.day + 1, 10),
        ),
      ]);
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.deliverySlots);
        return (response.data as List).cast<Map<String, dynamic>>();
      });
      return ApiResult.success(data
          .map((e) => DeliverySlotModel(
                id: e['id'].toString(),
                type: DeliverySlotType.values.byName(e['type'] as String),
                label: e['label'] as String,
              ))
          .toList());
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<OrderModel>> placeOrder({
    required double grandTotal,
    required String deliveryAddressLine,
    required String paymentMethodLabel,
    required String etaLabel,
    String? notes,
  }) async {
    if (ApiEndpoints.placeOrder.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 700));
      final orderId = 'QX${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      return ApiResult.success(OrderModel(
        orderId: orderId,
        placedAt: DateTime.now(),
        grandTotal: grandTotal,
        etaLabel: etaLabel,
        deliveryAddressLine: deliveryAddressLine,
        paymentMethodLabel: paymentMethodLabel,
      ));
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.post(ApiEndpoints.placeOrder, data: {
          'grand_total': grandTotal,
          'delivery_address_line': deliveryAddressLine,
          'payment_method_label': paymentMethodLabel,
          'notes': notes,
        });
        return response.data as Map<String, dynamic>;
      });
      return ApiResult.success(OrderModel.fromJson(data));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }
}
