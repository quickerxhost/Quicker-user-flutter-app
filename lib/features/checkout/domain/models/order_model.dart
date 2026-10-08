enum DeliverySlotType { instant, scheduled }

class DeliverySlotModel {
  final String id;
  final DeliverySlotType type;
  final String label; // "Instant (18 mins)" or "Today, 6:00 PM - 7:00 PM"
  final DateTime? windowStart;
  final DateTime? windowEnd;

  const DeliverySlotModel({required this.id, required this.type, required this.label, this.windowStart, this.windowEnd});
}

class OrderModel {
  final String orderId;
  final DateTime placedAt;
  final double grandTotal;
  final String etaLabel;
  final String deliveryAddressLine;
  final String paymentMethodLabel;

  const OrderModel({
    required this.orderId,
    required this.placedAt,
    required this.grandTotal,
    required this.etaLabel,
    required this.deliveryAddressLine,
    required this.paymentMethodLabel,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        orderId: json['order_id'].toString(),
        placedAt: DateTime.tryParse(json['placed_at'] as String? ?? '') ?? DateTime.now(),
        grandTotal: (json['grand_total'] as num).toDouble(),
        etaLabel: json['eta_label'] as String? ?? '',
        deliveryAddressLine: json['delivery_address_line'] as String? ?? '',
        paymentMethodLabel: json['payment_method_label'] as String? ?? '',
      );
}
