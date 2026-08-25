import '../../../restaurants/domain/models/restaurant_model.dart';

enum FoodTag { bestseller, mustTry, trending, recommended, popular }

class AddOnOption {
  final String id;
  final String label;
  final double price;
  const AddOnOption({required this.id, required this.label, required this.price});
}

class AddOnGroup {
  final String id;
  final String title; // e.g. "Choose Spice Level", "Add Extra Toppings"
  final bool singleSelect; // true = radio (spice level), false = checkboxes (add-ons)
  final bool required;
  final List<AddOnOption> options;

  const AddOnGroup({required this.id, required this.title, this.singleSelect = false, this.required = false, required this.options});
}

class FoodItemModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final FoodPurity purity;
  final List<FoodTag> tags;
  final bool hasCustomization;
  final int prepTimeMinutes;
  final List<String>? ingredients;
  final Map<String, String>? nutrition;
  final List<AddOnGroup> addOnGroups;

  const FoodItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.purity = FoodPurity.veg,
    this.tags = const [],
    this.hasCustomization = false,
    this.prepTimeMinutes = 20,
    this.ingredients,
    this.nutrition,
    this.addOnGroups = const [],
  });

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: json['id'].toString(),
      restaurantId: json['restaurant_id'].toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      purity: FoodPurity.values.byName(json['purity'] as String? ?? 'veg'),
      hasCustomization: json['has_customization'] as bool? ?? false,
      prepTimeMinutes: json['prep_time_minutes'] as int? ?? 20,
      ingredients: (json['ingredients'] as List?)?.cast<String>(),
      nutrition: (json['nutrition'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
}

class MenuCategoryModel {
  final String id;
  final String title;
  final List<FoodItemModel> items;
  const MenuCategoryModel({required this.id, required this.title, required this.items});
}
