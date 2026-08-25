import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/application/cart_controller.dart';
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
                childAspectRatio: 0.68,
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
                return SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: GestureDetector(
                          onTap: () => context.push('${RoutePaths.productDetails}/${product.id}', extra: product),
                          child: ProductCard(product: product, onToggleWishlist: () => controller.toggleWishlist(product.id)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
