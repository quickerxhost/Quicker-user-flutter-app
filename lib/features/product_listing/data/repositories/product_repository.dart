import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../home/domain/models/product_model.dart';

enum ProductSort { relevance, priceLowToHigh, priceHighToLow, newest }

/// Serves the hub's live master catalog through the public endpoint
/// (`GET /public/catalog/products`); `categoryId` is the backend category
/// UUID (optional — when null the whole hub catalog is returned).
class ProductRepository {
  ProductRepository(this._client);
  final DioClient _client;

  Future<ApiResult<List<ProductModel>>> getProducts({
    String? categoryId,
    required int page,
    int pageSize = 10,
    ProductSort sort = ProductSort.relevance,
  }) async {
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.publicProducts, queryParameters: {
          if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        });
        final list = (response.data as List? ?? []).cast<Map<String, dynamic>>();
        return list.map(ProductModel.fromCustomerJson).toList();
      });
      return ApiResult.success(_paginate(data, page: page, pageSize: pageSize));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  List<ProductModel> _paginate(List<ProductModel> all, {required int page, required int pageSize}) {
    final start = (page - 1) * pageSize;
    if (start >= all.length) return const [];
    return all.sublist(start, (start + pageSize).clamp(0, all.length));
  }
}
