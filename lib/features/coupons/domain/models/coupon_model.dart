enum CouponScope { platform, shop, restaurant }

class CouponModel {
  final String code;
  final String title;
  final String description;
  final CouponScope scope;
  final double discountValue; // flat amount or percent, see isPercent
  final bool isPercent;
  final double? maxDiscount;
  final double minOrderValue;
  final bool isRecommended;
  final DateTime? expiresAt;

  const CouponModel({
    required this.code,
    required this.title,
    required this.description,
    required this.scope,
    required this.discountValue,
    this.isPercent = false,
    this.maxDiscount,
    this.minOrderValue = 0,
    this.isRecommended = false,
    this.expiresAt,
  });

  /// Computes the discount for a given [orderValue], respecting
  /// [minOrderValue] and [maxDiscount].
  double discountFor(double orderValue) {
    if (orderValue < minOrderValue) return 0;
    final raw = isPercent ? orderValue * (discountValue / 100) : discountValue;
    if (maxDiscount != null) return raw.clamp(0, maxDiscount!);
    return raw;
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      scope: CouponScope.values.byName(json['scope'] as String? ?? 'platform'),
      discountValue: (json['discount_value'] as num).toDouble(),
      isPercent: json['is_percent'] as bool? ?? false,
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      minOrderValue: (json['min_order_value'] as num?)?.toDouble() ?? 0,
      isRecommended: json['is_recommended'] as bool? ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
    );
  }
}
