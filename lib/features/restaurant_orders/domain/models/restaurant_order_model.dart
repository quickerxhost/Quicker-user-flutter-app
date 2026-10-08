enum RestaurantOrderStatus { placed, accepted, preparing, pickedUp, outForDelivery, delivered, cancelled }

class RiderModel {
  final String name;
  final double rating;
  final String vehicleLabel; // "Electric Bike • MH 01 DX 4402"
  final bool verified;
  final double? latitude;
  final double? longitude;

  const RiderModel({required this.name, required this.rating, required this.vehicleLabel, this.verified = true, this.latitude, this.longitude});
}

class RestaurantOrderModel {
  final String orderId;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImageUrl;
  final String restaurantAddress;
  final String restaurantPhone;
  final DateTime placedAt;
  final RestaurantOrderStatus status;
  final int itemCount;
  final double grandTotal;
  final String etaLabel;
  final String deliveryAddressLine;
  final String paymentMethodLabel;
  final RiderModel? rider;
  final String? deliveryOtp;

  const RestaurantOrderModel({
    required this.orderId,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.restaurantAddress,
    required this.restaurantPhone,
    required this.placedAt,
    required this.status,
    required this.itemCount,
    required this.grandTotal,
    required this.etaLabel,
    required this.deliveryAddressLine,
    required this.paymentMethodLabel,
    this.rider,
    this.deliveryOtp,
  });

  factory RestaurantOrderModel.fromJson(Map<String, dynamic> json) {
    return RestaurantOrderModel(
      orderId: json['order_id'].toString(),
      restaurantId: json['restaurant_id'].toString(),
      restaurantName: json['restaurant_name'] as String? ?? '',
      restaurantImageUrl: json['restaurant_image_url'] as String? ?? '',
      restaurantAddress: json['restaurant_address'] as String? ?? '',
      restaurantPhone: json['restaurant_phone'] as String? ?? '',
      placedAt: DateTime.tryParse(json['placed_at'] as String? ?? '') ?? DateTime.now(),
      status: RestaurantOrderStatus.values.byName(json['status'] as String? ?? 'placed'),
      itemCount: json['item_count'] as int? ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      etaLabel: json['eta_label'] as String? ?? '',
      deliveryAddressLine: json['delivery_address_line'] as String? ?? '',
      paymentMethodLabel: json['payment_method_label'] as String? ?? '',
      deliveryOtp: json['delivery_otp'] as String?,
    );
  }
}
