enum FoodPurity { veg, nonVeg, pureVeg }

class RestaurantModel {
  final String id;
  final String name;
  final String imageUrl;
  final String cuisineTags; // "North Indian • Biryani • Mughlai"
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final int etaMinutes;
  final double costForTwo;
  final FoodPurity purity;
  final bool freeDelivery;
  final bool isBestseller;
  final bool isNew;
  final String openingHours;
  final double minOrderValue;
  final double deliveryCharge;
  final String? licenseFssai;
  final String address;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.cuisineTags,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.etaMinutes,
    required this.costForTwo,
    this.purity = FoodPurity.nonVeg,
    this.freeDelivery = false,
    this.isBestseller = false,
    this.isNew = false,
    this.openingHours = '10:00 AM - 11:00 PM',
    this.minOrderValue = 99,
    this.deliveryCharge = 40,
    this.licenseFssai,
    this.address = '',
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      cuisineTags: json['cuisine_tags'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      etaMinutes: json['eta_minutes'] as int? ?? 0,
      costForTwo: (json['cost_for_two'] as num?)?.toDouble() ?? 0,
      purity: FoodPurity.values.byName(json['purity'] as String? ?? 'nonVeg'),
      freeDelivery: json['free_delivery'] as bool? ?? false,
      isBestseller: json['is_bestseller'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      openingHours: json['opening_hours'] as String? ?? '',
      minOrderValue: (json['min_order_value'] as num?)?.toDouble() ?? 0,
      deliveryCharge: (json['delivery_charge'] as num?)?.toDouble() ?? 0,
      licenseFssai: json['license_fssai'] as String?,
      address: json['address'] as String? ?? '',
    );
  }
}
