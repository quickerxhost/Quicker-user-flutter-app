import 'package:flutter/material.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../home/domain/models/category_model.dart';

/// Serves the hub's live categories through the public endpoint
/// (`GET /public/catalog/categories`); falls back to a fixture catalogue
/// when the backend is unreachable.
class CategoryRepository {
  CategoryRepository(this._client);
  final DioClient _client;

  Future<ApiResult<List<CategoryModel>>> getAllCategories() async {
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.publicCategories);
        return (response.data as List? ?? []).cast<Map<String, dynamic>>();
      });
      final categories = data.map(CategoryModel.fromJson).toList();
      if (categories.isNotEmpty) return ApiResult.success(categories);
      return const ApiResult.success(_fixture);
    } on NetworkException {
      return const ApiResult.success(_fixture);
    }
  }

  static const _fixture = <CategoryModel>[
    CategoryModel(id: 'grocery', name: 'Grocery', icon: Icons.local_grocery_store_outlined),
    CategoryModel(id: 'vegetables', name: 'Vegetables', icon: Icons.eco_outlined),
    CategoryModel(id: 'bakery', name: 'Bakery', icon: Icons.bakery_dining_outlined),
    CategoryModel(id: 'dairy', name: 'Dairy', icon: Icons.egg_alt_outlined),
    CategoryModel(id: 'fashion', name: 'Fashion', icon: Icons.checkroom_outlined),
    CategoryModel(id: 'footwear', name: 'Footwear', icon: Icons.roller_skating_outlined),
    CategoryModel(id: 'electronics', name: 'Electronics', icon: Icons.devices_outlined),
    CategoryModel(id: 'restaurant', name: 'Restaurant', icon: Icons.restaurant_outlined),
    CategoryModel(id: 'sports', name: 'Sports', icon: Icons.sports_basketball_outlined),
    CategoryModel(id: 'books', name: 'Books', icon: Icons.menu_book_outlined),
    CategoryModel(id: 'cosmetics', name: 'Cosmetics', icon: Icons.face_retouching_natural_outlined),
    CategoryModel(id: 'stationery', name: 'Stationery', icon: Icons.edit_note_outlined),
    CategoryModel(id: 'hardware', name: 'Hardware', icon: Icons.build_outlined),
    CategoryModel(id: 'pet_supplies', name: 'Pet Supplies', icon: Icons.pets_outlined),
    CategoryModel(id: 'baby_care', name: 'Baby Care', icon: Icons.child_care_outlined),
  ];
}
