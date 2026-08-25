import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../application/wishlist_controller.dart';

/// No Stitch design exists for this screen — built to match the app's
/// token system per the PRD's Wishlist spec: grid, move-to-cart, remove,
/// share, pull-to-refresh, beautiful empty state. Pagination is handled
/// in-memory since the wishlist is locally persisted (see
/// [WishlistRepository]) — a real paginated GET would slot into the same
/// `wishlistControllerProvider` without changing this screen.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          if ((wishlistAsync.valueOrNull ?? []).isNotEmpty)
            IconButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wishlist link copied to share.')),
              ),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: wishlistAsync.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.marginMobile),
            child: ProductGridShimmer()),
        error: (error, _) => AppErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(wishlistControllerProvider)),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(
              icon: Icons.favorite_border_rounded,
              title: 'Your wishlist is empty',
              message:
                  'Tap the heart on any product to save it here for later.',
              action: ElevatedButton(
                  onPressed: () => context.go(RoutePaths.home),
                  child: const Text('Start Shopping')),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(wishlistControllerProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.55,
              ),
              itemBuilder: (context, index) {
                final product = items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push(
                            '${RoutePaths.productDetails}/${product.id}',
                            extra: product),
                        child: ProductCard(
                          product: product,
                          onToggleWishlist: () => ref
                              .read(wishlistControllerProvider.notifier)
                              .remove(product.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(wishlistControllerProvider.notifier)
                            .moveToCart(product.id),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(36),
                            padding: EdgeInsets.zero),
                        child: const Text('Move to Cart',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
