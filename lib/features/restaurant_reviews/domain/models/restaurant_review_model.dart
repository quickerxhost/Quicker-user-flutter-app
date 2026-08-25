class RestaurantReviewModel {
  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final double restaurantRating;
  final double foodRating;
  final double deliveryRating;
  final String comment;
  final List<String> imageUrls;
  final DateTime date;
  final int helpfulCount;

  const RestaurantReviewModel({
    required this.id,
    required this.authorName,
    this.authorAvatarUrl,
    required this.restaurantRating,
    required this.foodRating,
    required this.deliveryRating,
    required this.comment,
    this.imageUrls = const [],
    required this.date,
    this.helpfulCount = 0,
  });

  factory RestaurantReviewModel.fromJson(Map<String, dynamic> json) {
    return RestaurantReviewModel(
      id: json['id'].toString(),
      authorName: json['author_name'] as String? ?? 'Anonymous',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      restaurantRating: (json['restaurant_rating'] as num?)?.toDouble() ?? 0,
      foodRating: (json['food_rating'] as num?)?.toDouble() ?? 0,
      deliveryRating: (json['delivery_rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String? ?? '',
      imageUrls: (json['image_urls'] as List?)?.cast<String>() ?? const [],
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      helpfulCount: json['helpful_count'] as int? ?? 0,
    );
  }
}
