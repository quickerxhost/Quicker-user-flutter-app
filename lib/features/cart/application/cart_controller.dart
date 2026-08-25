import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../authentication/application/auth_controller.dart';
import '../../home/domain/models/product_model.dart';
import '../../wishlist/application/wishlist_controller.dart';
import '../data/repositories/cart_repository.dart';
import '../domain/models/cart_item_model.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(
    ref.watch(dioClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final cartControllerProvider =
    AsyncNotifierProvider<CartController, List<CartItemModel>>(
        CartController.new);

/// Derived provider that computes price summary from the cart async data
final cartPriceSummaryProvider = Provider<CartPriceSummary>((ref) {
  final items = ref.watch(cartControllerProvider).valueOrNull ?? [];
  final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
  final mrpTotal = items.fold<double>(0, (sum, i) => sum + i.lineMrpTotal);
  return CartPriceSummary(
    subtotal: subtotal,
    discount: (mrpTotal - subtotal).clamp(0, double.infinity),
    platformFee: items.isEmpty ? 0 : 9,
    deliveryCharge: items.isEmpty ? 0 : 25,
  );
});

/// Derived provider for total cart item count (for floating cart badge)
final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartControllerProvider).valueOrNull ?? [];
  return items.fold<int>(0, (sum, i) => sum + i.quantity);
});

/// Derived provider that computes grouped items from the cart async data
final cartGroupedByShopProvider = Provider<List<CartShopGroup>>((ref) {
  final items = ref.watch(cartControllerProvider).valueOrNull ?? [];
  final byShop = <String, List<CartItemModel>>{};
  for (final item in items) {
    byShop.putIfAbsent(item.shopId, () => []).add(item);
  }
  return byShop.entries
      .map((e) => CartShopGroup(
          shopId: e.key,
          shopName: e.value.first.shopName,
          etaMinutes: 18,
          items: e.value))
      .toList();
});

class CartController extends AsyncNotifier<List<CartItemModel>> {
  late final CartRepository _repository;

  @override
  Future<List<CartItemModel>> build() async {
    _repository = ref.read(cartRepositoryProvider);

    // Listen to auth state changes and sync cart when user logs in
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.user == null && next.user != null) {
        // User just logged in - sync local cart with backend
        syncWithBackend();
      }
    });

    return _repository.loadCart();
  }

  Future<void> _persist(List<CartItemModel> items) async {
    state = AsyncValue.data(items);
    await _repository.saveCart(items);
  }

  Future<void> addProduct(ProductModel product,
      {required String shopId,
      required String shopName,
      int quantity = 1}) async {
    final current = state.valueOrNull ?? [];
    final existingIndex =
        current.indexWhere((item) => item.product.id == product.id);
    List<CartItemModel> updated;
    if (existingIndex >= 0) {
      updated = [...current];
      updated[existingIndex] = updated[existingIndex]
          .copyWith(quantity: updated[existingIndex].quantity + quantity);
    } else {
      updated = [
        ...current,
        CartItemModel(
            id: 'cart-${product.id}',
            product: product,
            quantity: quantity,
            shopId: shopId,
            shopName: shopName),
      ];
    }
    await _persist(updated);
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    final current = state.valueOrNull ?? [];
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    final updated = current
        .map((item) =>
            item.id == cartItemId ? item.copyWith(quantity: quantity) : item)
        .toList();
    await _persist(updated);
  }

  /// Decrements the quantity of the cart line for [productId] (removes the
  /// line entirely when it would drop below 1) — used by product-card −
  /// buttons across Home/Search/Listing.
  Future<void> decrementProduct(String productId) async {
    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;
    final item = current[index];
    if (item.quantity <= 1) {
      await removeItem(item.id);
    } else {
      await updateQuantity(item.id, item.quantity - 1);
    }
  }

  Future<void> removeItem(String cartItemId) async {
    final current = state.valueOrNull ?? [];
    await _persist(current.where((item) => item.id != cartItemId).toList());
  }

  Future<void> clearCart() => _persist([]);

  Future<void> moveToSavedForLater(String cartItemId) async {
    final current = state.valueOrNull ?? [];
    final item = current.where((i) => i.id == cartItemId).toList();
    if (item.isEmpty) return;
    await ref.read(savedForLaterControllerProvider.notifier).add(item.first);
    await removeItem(cartItemId);
  }

  Future<void> moveToWishlist(String cartItemId) async {
    final current = state.valueOrNull ?? [];
    final item = current.where((i) => i.id == cartItemId).toList();
    if (item.isEmpty) return;
    await ref.read(wishlistControllerProvider.notifier).add(item.first.product);
    await removeItem(cartItemId);
  }

  /// Force sync local cart with backend (called when user logs in)
  Future<void> syncWithBackend() async {
    final items = state.valueOrNull ?? [];
    if (items.isEmpty) return;
    await _repository.saveCart(items); // This triggers the debounced sync
  }

  /// Groups the cart's items by shop for the Blinkit/BigBasket-style
  /// grouped layout — pure derived data, no extra state to keep in sync.
  List<CartShopGroup> get groupedByShop {
    final items = state.valueOrNull ?? [];
    final byShop = <String, List<CartItemModel>>{};
    for (final item in items) {
      byShop.putIfAbsent(item.shopId, () => []).add(item);
    }
    return byShop.entries
        .map((e) => CartShopGroup(
            shopId: e.key,
            shopName: e.value.first.shopName,
            etaMinutes: 18,
            items: e.value))
        .toList();
  }

  CartPriceSummary get priceSummary {
    final items = state.valueOrNull ?? [];
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final mrpTotal = items.fold<double>(0, (sum, i) => sum + i.lineMrpTotal);
    return CartPriceSummary(
      subtotal: subtotal,
      discount: (mrpTotal - subtotal).clamp(0, double.infinity),
      platformFee: items.isEmpty ? 0 : 9,
      deliveryCharge: items.isEmpty ? 0 : 25,
    );
  }
}

final savedForLaterControllerProvider =
    AsyncNotifierProvider<SavedForLaterController, List<CartItemModel>>(
        SavedForLaterController.new);

class SavedForLaterController extends AsyncNotifier<List<CartItemModel>> {
  late final CartRepository _repository;

  @override
  Future<List<CartItemModel>> build() async {
    _repository = ref.read(cartRepositoryProvider);
    return _repository.loadSavedForLater();
  }

  Future<void> add(CartItemModel item) async {
    final current = state.valueOrNull ?? [];
    final updated = [...current, item];
    state = AsyncValue.data(updated);
    await _repository.saveForLater(updated);
  }

  Future<void> remove(String cartItemId) async {
    final current = state.valueOrNull ?? [];
    final updated = current.where((i) => i.id != cartItemId).toList();
    state = AsyncValue.data(updated);
    await _repository.saveForLater(updated);
  }

  Future<void> moveToCart(String cartItemId) async {
    final current = state.valueOrNull ?? [];
    final item = current.where((i) => i.id == cartItemId).toList();
    if (item.isEmpty) return;
    await ref.read(cartControllerProvider.notifier).addProduct(
          item.first.product,
          shopId: item.first.shopId,
          shopName: item.first.shopName,
          quantity: item.first.quantity,
        );
    await remove(cartItemId);
  }
}
