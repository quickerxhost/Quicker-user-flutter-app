import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../cart/application/cart_controller.dart';
import '../../home/application/home_controller.dart';
import '../../home/domain/models/product_model.dart';
import '../data/repositories/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(dioClientProvider));
});

final wishlistControllerProvider = AsyncNotifierProvider<WishlistController, List<ProductModel>>(WishlistController.new);

class WishlistController extends AsyncNotifier<List<ProductModel>> {
  late final WishlistRepository _repository;

  @override
  Future<List<ProductModel>> build() async {
    _repository = ref.read(wishlistRepositoryProvider);
    return _repository.loadAll();
  }

  bool isWishlisted(String productId) => (state.valueOrNull ?? []).any((p) => p.id == productId);

  Future<void> add(ProductModel product) async {
    final current = state.valueOrNull ?? [];
    if (current.any((p) => p.id == product.id)) return;
    final updated = [...current, product.copyWith(isWishlisted: true)];
    state = AsyncValue.data(updated);
    await _repository.saveAll(updated);
  }

  Future<void> remove(String productId) async {
    final current = state.valueOrNull ?? [];
    final updated = current.where((p) => p.id != productId).toList();
    state = AsyncValue.data(updated);
    await _repository.saveAll(updated);
  }

  Future<void> toggle(ProductModel product) {
    return isWishlisted(product.id) ? remove(product.id) : add(product);
  }

  /// Moves a wishlist item into the cart using the current delivery hub context.
  /// Falls back to demo shop if no hub is available.
  Future<void> moveToCart(String productId) async {
    final current = state.valueOrNull ?? [];
    final product = current.where((p) => p.id == productId).toList();
    if (product.isEmpty) return;

    final hub = ref.read(homeFeedProvider).valueOrNull?.hub;
    final shopId = hub?.id.isNotEmpty == true ? hub!.id : 'demo-shop';
    final shopName = hub?.name.isNotEmpty == true ? hub!.name : 'QuickerX Store';

    await ref.read(cartControllerProvider.notifier).addProduct(
          product.first,
          shopId: shopId,
          shopName: shopName,
        );
    await remove(productId);
  }

  /// Sync wishlist with backend when endpoint becomes available.
  /// Currently a no-op since backend doesn't have wishlist endpoint.
  Future<void> syncWithBackend() async {
    // TODO: Implement when backend adds /wishlist endpoints
    // final items = state.valueOrNull ?? [];
    // await _repository.syncWithBackend(items);
  }
}
