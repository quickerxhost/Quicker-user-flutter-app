import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../home/domain/models/category_model.dart';
import '../../../home/domain/models/product_model.dart';

/// `ApiEndpoints.search` / `searchSuggestions` / `recentSearches` /
/// `trendingSearches` / `barcodeSearch` are currently BLANK — every method
/// below falls back to fixture data (matching Stitch `search_discovery`
/// copy) until the backend contracts are ready.
class SearchRepository {
  SearchRepository(this._client);
  final DioClient _client;

  static const _recent = ['Milk', 'Basmati Rice', 'Onions'];
  static const _trending = ['Mangoes', 'Ice Cream', 'Diapers', 'Monsoon Snacks'];

  Future<ApiResult<List<String>>> getRecentSearches() async {
    if (ApiEndpoints.recentSearches.isEmpty) return const ApiResult.success(_recent);
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.recentSearches);
        return (response.data as List).cast<String>();
      });
      return ApiResult.success(data);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<List<String>>> getTrendingSearches() async {
    if (ApiEndpoints.trendingSearches.isEmpty) return const ApiResult.success(_trending);
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.trendingSearches);
        return (response.data as List).cast<String>();
      });
      return ApiResult.success(data);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<List<CategoryModel>>> getPopularCategories() async {
    if (ApiEndpoints.categories.isEmpty) {
      return const ApiResult.success([]);
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.categories);
        return (response.data as List).cast<Map<String, dynamic>>();
      });
      return ApiResult.success(data.map(CategoryModel.fromJson).toList());
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<List<ProductModel>>> search(String query) async {
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.publicProducts);
        return (response.data as List? ?? []).cast<Map<String, dynamic>>();
      });
      final all = data.map(ProductModel.fromCustomerJson).toList();
      final filtered = query.trim().isEmpty
          ? all
          : all.where((p) => p.name.toLowerCase().contains(query.trim().toLowerCase())).toList();
      return ApiResult.success(filtered);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<ProductModel?>> searchByBarcode(String code) async {
    if (ApiEndpoints.barcodeSearch.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 400));
      return ApiResult.success(
        ProductModel(id: 'barcode-$code', name: 'Product for barcode $code', imageUrl: '', price: 99),
      );
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.barcodeSearch, queryParameters: {'code': code});
        return response.data as Map<String, dynamic>?;
      });
      return ApiResult.success(data == null ? null : ProductModel.fromJson(data));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }
}
