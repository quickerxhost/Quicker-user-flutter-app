import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../restaurant_menu/domain/models/food_item_model.dart';
import '../../../restaurants/domain/models/restaurant_model.dart';
import '../../domain/models/restaurant_cart_line_item.dart';

/// The backend has no restaurant module yet — persisted locally under its
/// own SharedPreferences key (`restaurant_cart_v1`), completely separate
/// from the Shopping Experience's grocery cart (`cart_items_v1`) so the two
/// carts never interfere with each other, matching how Swiggy/Zomato-style
/// apps keep food orders in their own basket.
class RestaurantCartRepository {
  RestaurantCartRepository(this._client);
  // ignore: unused_field
  final DioClient _client;

  static const _key = 'restaurant_cart_v1';
  static const _restaurantIdKey = 'restaurant_cart_restaurant_id_v1';

  Future<({String? restaurantId, List<RestaurantCartLineItem> items})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final restaurantId = prefs.getString(_restaurantIdKey);
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return (restaurantId: restaurantId, items: <RestaurantCartLineItem>[]);
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return (restaurantId: restaurantId, items: decoded.map(_fromCompactJson).toList());
  }

  Future<void> save(String? restaurantId, List<RestaurantCartLineItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map(_toCompactJson).toList()));
    if (restaurantId == null) {
      await prefs.remove(_restaurantIdKey);
    } else {
      await prefs.setString(_restaurantIdKey, restaurantId);
    }
    // NOTE: no backend restaurant module yet — sync the diff here when it lands.
  }

  Map<String, dynamic> _toCompactJson(RestaurantCartLineItem item) => {
        'id': item.id,
        'quantity': item.quantity,
        'selected_add_on_labels': item.selectedAddOnLabels,
        'add_ons_total': item.addOnsTotal,
        'instructions': item.instructions,
        'food': {
          'id': item.food.id,
          'restaurant_id': item.food.restaurantId,
          'name': item.food.name,
          'description': item.food.description,
          'price': item.food.price,
          'image_url': item.food.imageUrl,
          'purity': item.food.purity.name,
        },
      };

  RestaurantCartLineItem _fromCompactJson(Map<String, dynamic> json) {
    final foodJson = json['food'] as Map<String, dynamic>;
    return RestaurantCartLineItem(
      id: json['id'] as String,
      quantity: json['quantity'] as int,
      selectedAddOnLabels: (json['selected_add_on_labels'] as List?)?.cast<String>() ?? const [],
      addOnsTotal: (json['add_ons_total'] as num?)?.toDouble() ?? 0,
      instructions: json['instructions'] as String?,
      food: FoodItemModel(
        id: foodJson['id'] as String,
        restaurantId: foodJson['restaurant_id'] as String,
        name: foodJson['name'] as String,
        description: foodJson['description'] as String,
        price: (foodJson['price'] as num).toDouble(),
        imageUrl: foodJson['image_url'] as String,
        purity: FoodPurity.values.byName(foodJson['purity'] as String),
      ),
    );
  }
}
