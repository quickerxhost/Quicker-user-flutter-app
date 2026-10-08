import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../home/domain/models/product_model.dart';
import '../data/repositories/product_details_repository.dart';
import '../domain/models/product_detail_model.dart';

final productDetailsRepositoryProvider = Provider<ProductDetailsRepository>((ref) {
  return ProductDetailsRepository(ref.watch(dioClientProvider));
});

final productDetailProvider = FutureProvider.family<ProductDetailModel, String>((ref, productId) async {
  final result = await ref.watch(productDetailsRepositoryProvider).getProductDetail(productId);
  return result.when(success: (v) => v, failure: (e) => throw e);
});

final relatedProductsProvider = FutureProvider.family<List<ProductModel>, String>((ref, productId) async {
  final result = await ref.watch(productDetailsRepositoryProvider).getRelatedProducts(productId);
  return result.when(success: (v) => v, failure: (_) => const []);
});

final frequentlyBoughtTogetherProvider = FutureProvider.family<List<ProductModel>, String>((ref, productId) async {
  final result = await ref.watch(productDetailsRepositoryProvider).getFrequentlyBoughtTogether(productId);
  return result.when(success: (v) => v, failure: (_) => const []);
});

/// Quantity selector state, keyed per product so multiple product-detail
/// screens (e.g. reached via "Related Products") don't share one counter.
final productQuantityProvider = StateProvider.family<int, String>((ref, productId) => 1);
