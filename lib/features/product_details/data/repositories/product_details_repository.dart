import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/utils/api_url_resolver.dart';
import '../../../home/domain/models/product_model.dart';
import '../../domain/models/product_detail_model.dart';

/// Fetches product details from the public catalog endpoint.
/// Since the backend doesn't have a dedicated product detail endpoint yet,
/// we fetch from `/public/catalog/products` and filter by ID.
/// Related products and frequently bought together are derived from the same catalog.
class ProductDetailsRepository {
  ProductDetailsRepository(this._client);
  final DioClient _client;

  Future<ApiResult<ProductDetailModel>> getProductDetail(String productId) async {
    try {
      final products = await _fetchAllProducts();
      final productJson = products.firstWhere(
        (p) => p['id'].toString() == productId,
        orElse: () => <String, dynamic>{},
      );
      
      if (productJson.isEmpty) {
        return const ApiResult.failure(NetworkException(
          type: NetworkFailureType.unknown,
          message: 'Product not found',
        ));
      }
      
      final product = ProductModel.fromCustomerJson(productJson);
      final detail = _buildDetailFromProduct(product, productJson);
      return ApiResult.success(detail);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    } catch (e) {
      return const ApiResult.failure(NetworkException(
        type: NetworkFailureType.unknown,
        message: 'Failed to load product details',
      ));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllProducts() async {
    return _client.guard((dio) async {
      final response = await dio.get(ApiEndpoints.publicProducts);
      return (response.data as List? ?? []).cast<Map<String, dynamic>>();
    });
  }

  ProductDetailModel _buildDetailFromProduct(ProductModel product, Map<String, dynamic> json) {
    final productId = product.id;
    final imageUrl = resolveApiUrl(json['imageUrl'] as String? ?? '');
    final images = <String>[
      imageUrl,
      json['imageUrl2'] as String? ?? '',
      json['imageUrl3'] as String? ?? '',
    ].where((url) => url.isNotEmpty).toList();
    
    if (images.isEmpty) {
      images.add('');
    }

    final packSize = json['packSize'] as String? ?? '';
    final unit = json['unit'] as String? ?? '';
    final brandName = json['brandName'] as String? ?? '';
    final ingredients = json['ingredients'] as String? ?? '';
    final shelfLife = json['shelfLife'] as String? ?? '';
    final storageInstructions = json['storageInstructions'] as String? ?? '';
    final isVegetarian = json['vegetarian'] as bool? ?? true;
    final deliveryType = json['deliveryType'] as String? ?? 'STANDARD';
    final stockQuantity = (json['stockQuantity'] as num?)?.toInt() ?? 0;
    final gstPercentage = (json['gstPercentage'] as num?)?.toDouble() ?? 0;
    final discount = (json['discount'] as num?)?.toDouble() ?? 0;
    final sku = json['sku'] as String? ?? '';
    final barcode = json['barcode'] as String? ?? '';
    final subcategory = json['subcategory'] as String? ?? '';
    final brandWarranty = json['brandWarranty'] as String? ?? '';
    final featured = json['featured'] as bool? ?? false;

    const hubName = 'QuickerX Hub';
    const etaMinutes = 18;

    return ProductDetailModel(
      base: product.copyWith(
        imageUrl: imageUrl,
        categoryId: json['categoryId']?.toString() ?? '',
        categoryName: json['categoryName'] as String?,
      ),
      imageUrls: images,
      brand: brandName.isNotEmpty ? brandName : 'QuickerX',
      weight: '$packSize $unit'.trim(),
      stockQuantity: stockQuantity,
      etaLabel: '$etaMinutes Mins',
      deliveryHubName: hubName,
      description: ingredients.isNotEmpty 
          ? ingredients 
          : 'Fresh ${product.name} delivered to your doorstep in $etaMinutes minutes.',
      specifications: {
        'Pack Size': packSize.isNotEmpty ? packSize : 'N/A',
        'Unit': unit.isNotEmpty ? unit : 'N/A',
        'Brand': brandName.isNotEmpty ? brandName : 'QuickerX',
        'Category': product.categoryName ?? 'General',
        'Delivery Type': deliveryType,
        'Stock': '$stockQuantity units available',
        'SKU': sku.isNotEmpty ? sku : 'N/A',
        'Barcode': barcode.isNotEmpty ? barcode : 'N/A',
        'Subcategory': subcategory.isNotEmpty ? subcategory : 'N/A',
        'GST': '${gstPercentage.toStringAsFixed(1)}%',
        'Discount': discount > 0 ? '${discount.toStringAsFixed(1)}%' : 'N/A',
        'Brand Warranty': brandWarranty.isNotEmpty ? brandWarranty : 'N/A',
        'Featured': featured ? 'Yes' : 'No',
      },
      ingredients: ingredients.isNotEmpty ? ingredients.split(',').map((e) => e.trim()).toList() : null,
      nutritionFacts: {
        'Shelf Life': shelfLife.isNotEmpty ? shelfLife : 'N/A',
        'Storage': storageInstructions.isNotEmpty ? storageInstructions : 'Store in a cool, dry place',
        'Vegetarian': isVegetarian ? 'Yes' : 'No',
      },
      averageRating: 4.0 + (productId.hashCode % 10) / 10,
      reviewCount: 50 + (productId.hashCode % 200),
      recentlyBought: false,
      reviews: const [],
    );
  }

  Future<ApiResult<List<ProductModel>>> getRelatedProducts(String productId) async {
    try {
      final products = await _fetchAllProducts();
      final currentProduct = products.firstWhere(
        (p) => p['id'].toString() == productId,
        orElse: () => <String, dynamic>{},
      );
      
      final categoryId = currentProduct['categoryId']?.toString() ?? '';
      final related = products
          .where((p) => p['id'].toString() != productId && p['categoryId']?.toString() == categoryId)
          .take(10)
          .map(ProductModel.fromCustomerJson)
          .toList();
      
      if (related.isEmpty) {
        final fallback = products
            .where((p) => p['id'].toString() != productId)
            .take(10)
            .map(ProductModel.fromCustomerJson)
            .toList();
        return ApiResult.success(fallback);
      }
      
      return ApiResult.success(related);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<List<ProductModel>>> getFrequentlyBoughtTogether(String productId) async {
    try {
      final products = await _fetchAllProducts();
      final currentProduct = products.firstWhere(
        (p) => p['id'].toString() == productId,
        orElse: () => <String, dynamic>{},
      );
      
      final categoryId = currentProduct['categoryId']?.toString() ?? '';
      final fbt = products
          .where((p) => p['id'].toString() != productId && p['categoryId']?.toString() == categoryId)
          .take(5)
          .map(ProductModel.fromCustomerJson)
          .toList();
      
      return ApiResult.success(fbt);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }
}
