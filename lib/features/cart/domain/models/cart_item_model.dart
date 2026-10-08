import '../../../home/domain/models/product_model.dart';

class CartItemModel {
  final String id; // cart-line id (distinct from productId once variants exist)
  final ProductModel product;
  final int quantity;
  final String? variantLabel;
  final String shopId;
  final String shopName;

  const CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    this.variantLabel,
    required this.shopId,
    required this.shopName,
  });

  double get lineTotal => product.price * quantity;
  double get lineMrpTotal => (product.originalPrice ?? product.price) * quantity;

  CartItemModel copyWith({int? quantity}) => CartItemModel(
        id: id,
        product: product,
        quantity: quantity ?? this.quantity,
        variantLabel: variantLabel,
        shopId: shopId,
        shopName: shopName,
      );

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'].toString(),
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
      variantLabel: json['variant_label'] as String?,
      shopId: json['shop_id'].toString(),
      shopName: json['shop_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': product.id,
        'quantity': quantity,
        'variant_label': variantLabel,
        'shop_id': shopId,
        'shop_name': shopName,
      };
}

/// One shop's group of cart lines — the cart screen groups line items by
/// [shopName] the way Blinkit/BigBasket separate multi-store baskets.
class CartShopGroup {
  final String shopId;
  final String shopName;
  final int etaMinutes;
  final List<CartItemModel> items;

  const CartShopGroup({required this.shopId, required this.shopName, required this.etaMinutes, required this.items});

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
}

class CartPriceSummary {
  final double subtotal;
  final double discount;
  final double platformFee;
  final double deliveryCharge;
  final double couponDiscount;
  final double tax;

  const CartPriceSummary({
    required this.subtotal,
    required this.discount,
    this.platformFee = 9,
    this.deliveryCharge = 25,
    this.couponDiscount = 0,
    this.tax = 0,
  });

  double get grandTotal => (subtotal - discount - couponDiscount + platformFee + deliveryCharge + tax).clamp(0, double.infinity);
}
