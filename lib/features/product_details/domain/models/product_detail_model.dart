import '../../../home/domain/models/product_model.dart';

class ReviewModel {
  final String id;
  final String authorName;
  final double rating;
  final String comment;
  final DateTime date;

  const ReviewModel({required this.id, required this.authorName, required this.rating, required this.comment, required this.date});

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'].toString(),
        authorName: json['author_name'] as String? ?? 'Anonymous',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        comment: json['comment'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
}

class ProductDetailModel {
  final ProductModel base;
  final List<String> imageUrls;
  final String brand;
  final String weight;
  final int stockQuantity;
  final String etaLabel;
  final String deliveryHubName;
  final String description;
  final Map<String, String> specifications;
  final List<String>? ingredients;
  final Map<String, String>? nutritionFacts; // per 100g/serving
  final double averageRating;
  final int reviewCount;
  final List<ReviewModel> reviews;
  final bool recentlyBought;

  const ProductDetailModel({
    required this.base,
    required this.imageUrls,
    required this.brand,
    required this.weight,
    required this.stockQuantity,
    required this.etaLabel,
    required this.deliveryHubName,
    required this.description,
    required this.specifications,
    this.ingredients,
    this.nutritionFacts,
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
    this.recentlyBought = false,
  });

  bool get inStock => stockQuantity > 0;
  double get youSave => (base.originalPrice ?? base.price) - base.price;

  /// Builds a fully presentable detail view straight from a live catalog
  /// [product] (Home / Search / Listing / Wishlist tap-through) without
  /// waiting on the Phase-2 detail backend: the real name, image, price,
  /// pack meta and stock state are shown, enriched with the hub's delivery
  /// info and sensible placeholder extras.
  factory ProductDetailModel.fromProduct(
    ProductModel product, {
    required String hubName,
    required String etaLabel,
  }) {
    return ProductDetailModel(
      base: product,
      imageUrls: [if (product.imageUrl.isNotEmpty) product.imageUrl],
      brand: 'QuickerX',
      weight: product.meta ?? '',
      stockQuantity: product.inStock ? 10 : 0,
      etaLabel: etaLabel,
      deliveryHubName: hubName,
      description:
          'Fresh and quality-assured ${product.name}, sourced and delivered quickly to your doorstep by $hubName.',
      specifications: {
        if (product.meta != null && product.meta!.isNotEmpty) 'Pack Size': product.meta!,
        if (product.categoryName != null && product.categoryName!.isNotEmpty) 'Category': product.categoryName!,
        'Fulfilled by': hubName,
      },
      averageRating: 4.5,
      reviewCount: 1,
      reviews: [
        ReviewModel(
          id: 'r1',
          authorName: 'QuickerX',
          rating: 5,
          comment: 'Quality checked and delivered fresh.',
          date: DateTime.now(),
        ),
      ],
      recentlyBought: true,
    );
  }

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      base: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      imageUrls: (json['image_urls'] as List? ?? []).cast<String>(),
      brand: json['brand'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      etaLabel: json['eta_label'] as String? ?? '',
      deliveryHubName: json['delivery_hub_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      specifications: (json['specifications'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), v.toString())),
      ingredients: (json['ingredients'] as List?)?.cast<String>(),
      nutritionFacts: (json['nutrition_facts'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())),
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      reviews: (json['reviews'] as List? ?? []).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList(),
      recentlyBought: json['recently_bought'] as bool? ?? false,
    );
  }
}
