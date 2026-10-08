import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../restaurants/domain/models/restaurant_model.dart';
import '../../domain/models/food_item_model.dart';

/// `ApiEndpoints.restaurantMenu` / `foodDetail` are currently BLANK — falls
/// back to fixture data mirroring the Stitch `the_spice_hub_menu` design
/// exactly (same category names, item names, prices, descriptions, tags)
/// for `the-spice-hub`; other restaurant ids get a smaller generic fixture
/// menu so every restaurant in the list is still browsable.
class MenuRepository {
  MenuRepository(this._client);
  final DioClient _client;

  Future<ApiResult<List<MenuCategoryModel>>> getMenu(String restaurantId) async {
    if (ApiEndpoints.restaurantMenu.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 400));
      return ApiResult.success(restaurantId == 'the-spice-hub' ? _spiceHubMenu() : _genericMenu(restaurantId));
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.restaurantMenu, queryParameters: {'restaurant_id': restaurantId});
        return (response.data as List).cast<Map<String, dynamic>>();
      });
      return ApiResult.success(data
          .map((c) => MenuCategoryModel(
                id: c['id'].toString(),
                title: c['title'] as String,
                items: (c['items'] as List).map((i) => FoodItemModel.fromJson(i as Map<String, dynamic>)).toList(),
              ))
          .toList());
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<FoodItemModel>> getFoodDetail(String foodId) async {
    if (ApiEndpoints.foodDetail.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      final all = [..._spiceHubMenu(), ..._genericMenu('generic')].expand((c) => c.items);
      final match = all.where((f) => f.id == foodId).toList();
      return ApiResult.success(match.isNotEmpty ? match.first : all.first);
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get('${ApiEndpoints.foodDetail}/$foodId');
        return response.data as Map<String, dynamic>;
      });
      return ApiResult.success(FoodItemModel.fromJson(data));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  List<MenuCategoryModel> _spiceHubMenu() {
    const rid = 'the-spice-hub';
    return [
      const MenuCategoryModel(id: 'recommended', title: 'Recommended', items: [
        FoodItemModel(
          id: 'paneer-tikka',
          restaurantId: rid,
          name: 'Classic Paneer Tikka',
          description: 'Succulent cottage cheese cubes marinated in our secret hub spices and grilled to perfection in clay oven.',
          price: 349,
          imageUrl: '',
          purity: FoodPurity.veg,
          tags: [FoodTag.bestseller],
          hasCustomization: true,
          prepTimeMinutes: 18,
          addOnGroups: [
            AddOnGroup(id: 'spice', title: 'Choose Spice Level', singleSelect: true, required: true, options: [
              AddOnOption(id: 'mild', label: 'Mild', price: 0),
              AddOnOption(id: 'medium', label: 'Medium', price: 0),
              AddOnOption(id: 'hot', label: 'Hot', price: 0),
            ]),
            AddOnGroup(id: 'extras', title: 'Add Extra', options: [
              AddOnOption(id: 'mint-chutney', label: 'Extra Mint Chutney', price: 20),
              AddOnOption(id: 'extra-paneer', label: 'Extra Paneer', price: 60),
            ]),
          ],
        ),
        FoodItemModel(
          id: 'galouti-kebab',
          restaurantId: rid,
          name: 'Smoked Galouti Kebab',
          description: 'Traditional melt-in-mouth lamb kebabs infused with sandalwood smoke and exotic spices. Served with Ulte Tawe ka Paratha.',
          price: 499,
          imageUrl: '',
          purity: FoodPurity.nonVeg,
          tags: [FoodTag.mustTry],
          prepTimeMinutes: 25,
        ),
        FoodItemModel(
          id: 'dahi-sholay',
          restaurantId: rid,
          name: 'Dahi Ke Sholay',
          description: 'Crispy bread pockets filled with spicy hung curd, bell peppers, and fresh cilantro. A spice hub signature.',
          price: 289,
          imageUrl: '',
          purity: FoodPurity.veg,
          tags: [FoodTag.trending],
          prepTimeMinutes: 15,
        ),
      ]),
      const MenuCategoryModel(id: 'starters', title: 'Starters', items: [
        FoodItemModel(id: 'chicken-tikka', restaurantId: rid, name: 'Chicken Tikka Platter', description: 'Char-grilled chicken tikka served with mint chutney and salad.', price: 349, imageUrl: '', purity: FoodPurity.nonVeg, hasCustomization: true, prepTimeMinutes: 20),
        FoodItemModel(id: 'veg-seekh', restaurantId: rid, name: 'Veg Seekh Kebab', description: 'Spiced mixed-vegetable skewers grilled over charcoal.', price: 259, imageUrl: '', purity: FoodPurity.veg, prepTimeMinutes: 18),
      ]),
      const MenuCategoryModel(id: 'main-course', title: 'Main Course', items: [
        FoodItemModel(id: 'paneer-pizza', restaurantId: rid, name: 'Paneer Delight Pizza', description: 'Thin-crust pizza loaded with paneer, peppers and extra cheese.', price: 599, imageUrl: '', purity: FoodPurity.veg, tags: [FoodTag.popular], hasCustomization: true, prepTimeMinutes: 22),
        FoodItemModel(id: 'awadhi-biryani', restaurantId: rid, name: 'Awadhi Mutton Biryani', description: 'Slow-cooked dum biryani with tender mutton and saffron rice.', price: 449, imageUrl: '', purity: FoodPurity.nonVeg, tags: [FoodTag.bestseller], prepTimeMinutes: 30),
      ]),
      const MenuCategoryModel(id: 'desserts', title: 'Desserts', items: [
        FoodItemModel(id: 'shahi-tukda', restaurantId: rid, name: 'Shahi Tukda', description: 'Fried bread soaked in saffron-infused rabri, garnished with nuts.', price: 179, imageUrl: '', purity: FoodPurity.veg, prepTimeMinutes: 10),
      ]),
      const MenuCategoryModel(id: 'beverages', title: 'Beverages', items: [
        FoodItemModel(id: 'masala-chai', restaurantId: rid, name: 'Hub Special Masala Chai', description: "Freshly brewed spiced tea, the hub's signature blend.", price: 79, imageUrl: '', purity: FoodPurity.veg, prepTimeMinutes: 8),
      ]),
    ];
  }

  List<MenuCategoryModel> _genericMenu(String restaurantId) {
    return [
      MenuCategoryModel(id: 'popular', title: 'Popular Items', items: [
        FoodItemModel(id: '$restaurantId-item-1', restaurantId: restaurantId, name: "Chef's Special Combo", description: 'A crowd favorite, freshly prepared daily.', price: 299, imageUrl: '', purity: FoodPurity.veg, tags: const [FoodTag.popular], prepTimeMinutes: 20),
        FoodItemModel(id: '$restaurantId-item-2', restaurantId: restaurantId, name: 'House Special Platter', description: 'Our most-ordered dish, made to order.', price: 399, imageUrl: '', purity: FoodPurity.nonVeg, tags: const [FoodTag.bestseller], prepTimeMinutes: 25),
      ]),
    ];
  }
}
