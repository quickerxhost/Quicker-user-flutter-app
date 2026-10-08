import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/application/cart_controller.dart';
import '../../home/domain/models/product_model.dart';
import '../application/product_listing_controller.dart';
import '../data/repositories/product_repository.dart';

/// No single Stitch design exists for this exact screen — built with the
/// shared `ProductCard`/shimmer/error components to match the PRD's
/// "Product Listing Screen" spec: grid/list toggle, filter, sort, discount
/// badge, stock, price, add-to-cart, shimmer loading, pagination.
class ProductListingScreen extends ConsumerStatefulWidget {
  const ProductListingScreen({super.key, this.categoryId, required this.categoryName});
  final String? categoryId;
  final String categoryName;

  @override
  ConsumerState<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends ConsumerState<ProductListingScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
        ref.read(productListingControllerProvider(widget.categoryId).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = productListingControllerProvider(widget.categoryId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            onPressed: controller.toggleLayout,
            icon: Icon(state.layout == ListLayout.grid ? Icons.view_list_rounded : Icons.grid_view_rounded),
          ),
          IconButton(
            onPressed: () => _showSortSheet(context, controller, state.sort),
            icon: const Icon(Icons.sort_rounded),
          ),
        ],
      ),
      body: _buildBody(state, controller),
    );
  }

  void _showSortSheet(BuildContext context, ProductListingController controller, ProductSort current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Sort By', style: AppTypography.titleLg()),
              ),
              RadioGroup<ProductSort>(
                groupValue: current,
                onChanged: (value) {
                  if (value != null) controller.changeSort(value);
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ProductSort.values
                      .map((sort) => RadioListTile<ProductSort>(
                            value: sort,
                            title: Text(_sortLabel(sort)),
                            activeColor: AppColors.primary,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _sortLabel(ProductSort sort) => switch (sort) {
        ProductSort.relevance => 'Relevance',
        ProductSort.priceLowToHigh => 'Price: Low to High',
        ProductSort.priceHighToLow => 'Price: High to Low',
        ProductSort.newest => 'Newest First',
      };

  Widget _buildBody(ProductListingState state, ProductListingController controller) {
    if (state.isInitialLoading) {
      return const Padding(padding: EdgeInsets.all(AppSpacing.marginMobile), child: ProductGridShimmer(itemCount: 6));
    }
    if (state.errorMessage != null && state.products.isEmpty) {
      return AppErrorView(message: state.errorMessage!, onRetry: controller.loadFirstPage);
    }
    if (state.products.isEmpty) {
      return const EmptyView(icon: Icons.inventory_2_outlined, title: 'No products found', message: 'Check back soon!');
    }

    return RefreshIndicator(
      onRefresh: controller.loadFirstPage,
      child: state.layout == ListLayout.grid
          ? GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              itemCount: state.products.length + (state.hasMore ? 1 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.56,
              ),
              itemBuilder: (context, index) {
                if (index >= state.products.length) return const ProductCardShimmer();
                final product = state.products[index];
                return GestureDetector(
                  onTap: () => context.push('${RoutePaths.productDetails}/${product.id}', extra: product),
                  child: ProductCard(
                    product: product,
                    onToggleWishlist: () => controller.toggleWishlist(product.id),
                    onAddToCart: () async {
                      await ref.read(cartControllerProvider.notifier).addProduct(product, shopId: 'demo-shop', shopName: 'QuickerX Store');
                    },
                    onRemoveFromCart: () =>
                        ref.read(cartControllerProvider.notifier).decrementProduct(product.id),
                  ),
                );
              },
            )
          : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              itemCount: state.products.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index >= state.products.length) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
                }
                final product = state.products[index];
                return _ProductListItem(
                  product: product,
                  onTap: () => context.push('${RoutePaths.productDetails}/${product.id}', extra: product),
                  onAddToCart: () async {
                    await ref.read(cartControllerProvider.notifier).addProduct(product, shopId: 'demo-shop', shopName: 'QuickerX Store');
                  },
                  onRemoveFromCart: () =>
                      ref.read(cartControllerProvider.notifier).decrementProduct(product.id),
                );
              },
            ),
    );
  }
}

/// Horizontal product item for list view layout
class _ProductListItem extends ConsumerWidget {
  const _ProductListItem({
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.onRemoveFromCart,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onRemoveFromCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartControllerProvider).valueOrNull ?? [];
    final quantity = cartItems
        .where((item) => item.product.id == product.id)
        .fold<int>(0, (sum, item) => sum + item.quantity);
    final outOfStock = !product.inStock;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surfaceContainerHigh),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.image_not_supported_outlined, color: AppColors.outline, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  if (product.meta != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      product.meta!,
                      style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: AppTypography.labelLg(color: AppColors.primary).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (product.originalPrice != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${product.originalPrice!.toStringAsFixed(0)}',
                          style: AppTypography.labelLg(color: AppColors.outline).copyWith(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Add control
            if (!outOfStock && onAddToCart != null)
              quantity > 0
                  ? QuantityStepper(
                      compact: true,
                      quantity: quantity,
                      onIncrement: onAddToCart!,
                      onDecrement: onRemoveFromCart ?? () {},
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onAddToCart,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryContainer, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'ADD',
                            style: AppTypography.labelLg(color: Colors.white).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
