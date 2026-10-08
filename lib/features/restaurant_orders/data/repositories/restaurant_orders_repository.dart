import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/restaurant_order_model.dart';

/// `ApiEndpoints.restaurantOrders` / `restaurantOrderDetail` /
/// `liveTracking` / `repeatOrder` are currently BLANK — order history
/// falls back to fixture data, and live tracking is simulated with a
/// timer that advances the order through
/// accepted -> preparing -> pickedUp -> outForDelivery -> delivered, so
/// the tracking screen's timeline/rider-marker UI is fully exercisable
/// before the backend + a real live-location feed exist.
class RestaurantOrdersRepository {
  RestaurantOrdersRepository(this._client);
  final DioClient _client;

  Future<ApiResult<List<RestaurantOrderModel>>> getOrders() async {
    if (ApiEndpoints.restaurantOrders.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 400));
      return ApiResult.success(_fixtureOrders());
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.restaurantOrders);
        return (response.data as List).cast<Map<String, dynamic>>();
      });
      return ApiResult.success(data.map(RestaurantOrderModel.fromJson).toList());
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  /// Emits a simulated status progression for [initial]. `ApiEndpoints.liveTracking`
  /// is blank, so this stream stands in for a real socket/polling feed —
  /// swap the body for a websocket/SSE listener once the backend exists;
  /// [RestaurantTrackingController] only depends on the stream's shape
  /// (`RestaurantOrderModel`), not this method.
  Stream<RestaurantOrderModel> watchOrderStatus(RestaurantOrderModel initial) async* {
    const sequence = [
      RestaurantOrderStatus.accepted,
      RestaurantOrderStatus.preparing,
      RestaurantOrderStatus.pickedUp,
      RestaurantOrderStatus.outForDelivery,
      RestaurantOrderStatus.delivered,
    ];
    var current = initial;
    yield current;
    for (final status in sequence) {
      await Future.delayed(const Duration(seconds: 6));
      current = RestaurantOrderModel(
        orderId: current.orderId,
        restaurantId: current.restaurantId,
        restaurantName: current.restaurantName,
        restaurantImageUrl: current.restaurantImageUrl,
        restaurantAddress: current.restaurantAddress,
        restaurantPhone: current.restaurantPhone,
        placedAt: current.placedAt,
        status: status,
        itemCount: current.itemCount,
        grandTotal: current.grandTotal,
        etaLabel: current.etaLabel,
        deliveryAddressLine: current.deliveryAddressLine,
        paymentMethodLabel: current.paymentMethodLabel,
        rider: status.index >= RestaurantOrderStatus.pickedUp.index
            ? const RiderModel(name: 'Rahul', rating: 4.9, vehicleLabel: 'Electric Bike • MH 01 DX 4402')
            : current.rider,
        deliveryOtp: current.deliveryOtp ?? '4821',
      );
      yield current;
    }
  }

  List<RestaurantOrderModel> _fixtureOrders() {
    final now = DateTime.now();
    return [
      RestaurantOrderModel(
        orderId: 'QX-88219',
        restaurantId: 'the-spice-hub',
        restaurantName: 'The Spice Hub',
        restaurantImageUrl: '',
        restaurantAddress: '12/B Art District, Midtown',
        restaurantPhone: '+91 98765 43210',
        placedAt: now.subtract(const Duration(minutes: 12)),
        status: RestaurantOrderStatus.outForDelivery,
        itemCount: 3,
        grandTotal: 1639.35,
        etaLabel: '8 mins',
        deliveryAddressLine: 'Apt 402, Oakwood Residences, 5th Avenue',
        paymentMethodLabel: 'UPI',
        rider: const RiderModel(name: 'Rahul', rating: 4.9, vehicleLabel: 'Electric Bike • MH 01 DX 4402'),
        deliveryOtp: '4821',
      ),
      RestaurantOrderModel(
        orderId: 'QX-88104',
        restaurantId: 'burger-beast',
        restaurantName: 'Burger Beast',
        restaurantImageUrl: '',
        restaurantAddress: 'Shop 3, Central Market',
        restaurantPhone: '+91 91234 56789',
        placedAt: now.subtract(const Duration(days: 2)),
        status: RestaurantOrderStatus.delivered,
        itemCount: 2,
        grandTotal: 458,
        etaLabel: 'Delivered',
        deliveryAddressLine: 'Apt 402, Oakwood Residences, 5th Avenue',
        paymentMethodLabel: 'Cash on Delivery',
      ),
      RestaurantOrderModel(
        orderId: 'QX-87990',
        restaurantId: 'bella-cucina',
        restaurantName: 'Bella Cucina',
        restaurantImageUrl: '',
        restaurantAddress: '4th Cross, Riverside Road',
        restaurantPhone: '+91 99887 66554',
        placedAt: now.subtract(const Duration(days: 6)),
        status: RestaurantOrderStatus.cancelled,
        itemCount: 1,
        grandTotal: 799,
        etaLabel: 'Cancelled',
        deliveryAddressLine: 'Apt 402, Oakwood Residences, 5th Avenue',
        paymentMethodLabel: 'Visa •••• 4242',
      ),
    ];
  }
}
