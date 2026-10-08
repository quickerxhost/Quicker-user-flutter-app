enum RestaurantDeliverySlotType { instant, scheduled }

class RestaurantDeliverySlotModel {
  final String id;
  final RestaurantDeliverySlotType type;
  final String label;
  final DateTime? windowStart;

  const RestaurantDeliverySlotModel({required this.id, required this.type, required this.label, this.windowStart});
}
