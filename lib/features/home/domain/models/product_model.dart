class ProductModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final String? meta; // e.g. "1 Liter • Tetra Pack" or "Reliance Fresh • 1.2km"
  final String? etaLabel; // e.g. "12 Mins"
  final bool isWishlisted;
  final bool inStock;
  final String categoryId;
  final String? categoryName;

  const ProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    this.meta,
    this.etaLabel,
    this.isWishlisted = false,
    this.inStock = true,
    this.categoryId = '',
    this.categoryName,
  });

  String? get discountLabel {
    if (originalPrice == null || originalPrice! <= price) return null;
    final pct = (((originalPrice! - price) / originalPrice!) * 100).round();
    return '$pct% OFF';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      meta: json['meta'] as String?,
      etaLabel: json['eta_label'] as String?,
      isWishlisted: json['is_wishlisted'] as bool? ?? false,
      inStock: json['in_stock'] as bool? ?? true,
    );
  }

  /// Backend customer-catalog shape (`GET /public/catalog/products`):
  /// `sellingPrice`, `mrp`, `packSize`, `unit`, `brandName`, `inStock`.
  factory ProductModel.fromCustomerJson(Map<String, dynamic> json) {
    final mrp = (json['mrp'] as num?)?.toDouble();
    final sellingPrice = (json['sellingPrice'] as num?)?.toDouble() ?? 0;
    final packSize = json['packSize'] as String? ?? '';
    final unit = json['unit'] as String? ?? '';
    final metaParts = [packSize, unit].where((s) => s.isNotEmpty).join(' · ');
    final brandName = json['brandName'] as String? ?? '';
    return ProductModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      price: sellingPrice,
      originalPrice: (mrp != null && mrp > sellingPrice) ? mrp : null,
      meta: metaParts.isNotEmpty ? metaParts : (brandName.isEmpty ? null : brandName),
      isWishlisted: false,
      inStock: json['inStock'] as bool? ?? true,
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName'] as String?,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? price,
    double? originalPrice,
    String? meta,
    String? etaLabel,
    bool? isWishlisted,
    bool? inStock,
    String? categoryId,
    String? categoryName,
  }) => ProductModel(
        id: id ?? this.id,
        name: name ?? this.name,
        imageUrl: imageUrl ?? this.imageUrl,
        price: price ?? this.price,
        originalPrice: originalPrice ?? this.originalPrice,
        meta: meta ?? this.meta,
        etaLabel: etaLabel ?? this.etaLabel,
        isWishlisted: isWishlisted ?? this.isWishlisted,
        inStock: inStock ?? this.inStock,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
      );
}
