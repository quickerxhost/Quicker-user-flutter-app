class DeliveryHubModel {
  final String id;
  final String name;
  final int etaMinutes;
  final int shopCount;
  final double? latitude;
  final double? longitude;

  const DeliveryHubModel({
    required this.id,
    required this.name,
    required this.etaMinutes,
    required this.shopCount,
    this.latitude,
    this.longitude,
  });

  factory DeliveryHubModel.fromJson(Map<String, dynamic> json) {
    return DeliveryHubModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      etaMinutes: json['eta_minutes'] as int? ?? 0,
      shopCount: json['shop_count'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
