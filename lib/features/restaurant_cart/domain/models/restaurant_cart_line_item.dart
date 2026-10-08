import '../../../restaurant_menu/domain/models/food_item_model.dart';

class RestaurantCartLineItem {
  final String id; // cart-line id
  final FoodItemModel food;
  final int quantity;
  final List<String> selectedAddOnLabels; // e.g. ["Extra Cheese", "Thin Crust"]
  final double addOnsTotal;
  final String? instructions;

  const RestaurantCartLineItem({
    required this.id,
    required this.food,
    required this.quantity,
    this.selectedAddOnLabels = const [],
    this.addOnsTotal = 0,
    this.instructions,
  });

  double get unitPrice => food.price + addOnsTotal;
  double get lineTotal => unitPrice * quantity;

  RestaurantCartLineItem copyWith({int? quantity, String? instructions}) => RestaurantCartLineItem(
        id: id,
        food: food,
        quantity: quantity ?? this.quantity,
        selectedAddOnLabels: selectedAddOnLabels,
        addOnsTotal: addOnsTotal,
        instructions: instructions ?? this.instructions,
      );
}

class RestaurantCartBillSummary {
  final double itemTotal;
  final double deliveryCharge;
  final double packingCharge;
  final double taxes;
  final double couponDiscount;
  final double coinsDiscount;

  const RestaurantCartBillSummary({
    required this.itemTotal,
    this.deliveryCharge = 40,
    this.packingCharge = 20,
    this.taxes = 0,
    this.couponDiscount = 0,
    this.coinsDiscount = 0,
  });

  double get grandTotal => (itemTotal + deliveryCharge + packingCharge + taxes - couponDiscount - coinsDiscount).clamp(0, double.infinity);
}
