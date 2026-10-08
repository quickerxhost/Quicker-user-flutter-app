import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/category_and_layout_widgets.dart';
import '../../../core/widgets/quickerx_card.dart';
import '../../../core/widgets/offer_and_hub_widgets.dart';
import '../../../core/widgets/search_and_nav_widgets.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/application/cart_controller.dart';
import '../../authentication/application/auth_controller.dart';
import '../application/home_controller.dart';
import '../domain/models/product_model.dart';

/// Matches Stitch `home_updated_categories`: sticky search bar (voice +
/// barcode-scan actions), Delivery Hub card, category row, offer banner
/// carousel, "Trending Near You" product grid, pull-to-refresh, floating
/// cart button.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(homeFeedProvider);
    final authUser = ref.watch(authControllerProvider).user;
    final cartItemCount = ref.watch(cartItemCountProvider);
    final greetingName = authUser?.fullName?.trim().isNotEmpty == true
        ? authUser!.fullName!.split(' ').first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: cartItemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push(RoutePaths.cart),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full)),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_rounded, size: 24),
                  if (cartItemCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            cartItemCount > 99
                                ? '99+'
                                : cartItemCount.toString(),
                            style: AppTypography.labelLg(color: Colors.white)
                                .copyWith(
                                    fontSize: 10, fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: Text(
                'View Cart',
                style: AppTypography.labelLg(color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(homeFeedProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.marginMobile,
                    AppSpacing.md,
                    AppSpacing.marginMobile,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: feedAsync.maybeWhen(
                          data: (feed) => Text(
                            'Good ${_greetingTime()}, ${greetingName ?? feed.greetingName} 👋',
                            style: AppTypography.titleLg(),
                          ),
                          orElse: () =>
                              const ShimmerBox(width: 180, height: 22),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push(RoutePaths.wishlist),
                        icon: const Icon(Icons.favorite_border_rounded,
                            color: AppColors.onSurface),
                      ),
                      IconButton(
                        onPressed: () => context.push(RoutePaths.profile),
                        icon: const Icon(Icons.notifications_none_rounded,
                            color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile),
                  child: AppSearchBar(
                    readOnly: true,
                    onTap: () => context.push(RoutePaths.search),
                    onVoiceTap: () => context.push(RoutePaths.voiceSearch),
                    onScanTap: () => context.push(RoutePaths.barcodeScanner),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: feedAsync.when(
                  data: (feed) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.marginMobile),
                    child: DeliveryHubCard(hub: feed.hub),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.marginMobile),
                    child: ShimmerBox(
                        width: double.infinity, height: 96, radius: 24),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // ---- Categories ----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile),
                  child: SectionHeader(
                    title: 'Browse Categories',
                    actionLabel: 'View All',
                    onActionTap: () => context.push(RoutePaths.categories),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: feedAsync.when(
                    data: (feed) => ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.marginMobile),
                      scrollDirection: Axis.horizontal,
                      itemCount: feed.categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) => CategoryCard(
                        category: feed.categories[index],
                        onTap: () => context.push(
                          RoutePaths.productListing,
                          extra: {
                            'categoryId': feed.categories[index].id,
                            'categoryName': feed.categories[index].name
                          },
                        ),
                      ),
                    ),
                    loading: () => ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.marginMobile),
                      scrollDirection: Axis.horizontal,
                      itemCount: 6,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (_, __) => const Column(
                        children: [
                          ShimmerBox(width: 64, height: 64, radius: 32),
                          SizedBox(height: 8),
                          ShimmerBox(width: 56, height: 10)
                        ],
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // ---- Offer banners ----
              SliverToBoxAdapter(
                child: feedAsync.maybeWhen(
                  data: (feed) => SizedBox(
                    height: 140,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.marginMobile),
                      scrollDirection: Axis.horizontal,
                      itemCount: feed.banners.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) => SizedBox(
                        width: MediaQuery.of(context).size.width -
                            (AppSpacing.marginMobile * 2) -
                            40,
                        child: OfferBanner(banner: feed.banners[index]),
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // ---- Restaurant highlight (entry point into the Restaurant module) ----
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile),
                  child: RestaurantBanner(
                    onTap: () => context.push(RoutePaths.restaurantHome),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // ---- All products (category-wise) ----
              const SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                  child: SectionHeader(
                    title: 'All Products',
                    leadingIcon: Icons.local_fire_department_rounded,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              feedAsync.when(
                data: (feed) {
                  if (feed.trendingProducts.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EmptyView(
                        icon: Icons.inventory_2_outlined,
                        title: 'No products yet',
                        message: 'Products from your hub will appear here.',
                      ),
                    );
                  }
                  final sections = <String, List<ProductModel>>{};
                  for (final category in feed.categories) {
                    sections[category.name] = [];
                  }
                  for (final product in feed.trendingProducts) {
                    final key = product.categoryName ?? 'Other';
                    sections.putIfAbsent(key, () => []).add(product);
                  }
                  final columnChildren = <Widget>[];
                  final cardWidth = (MediaQuery.sizeOf(context).width -
                          (AppSpacing.marginMobile * 2) -
                          AppSpacing.md) /
                      2;
                  sections.forEach((categoryName, products) {
                    if (products.isEmpty) return;
                    columnChildren.add(Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.marginMobile,
                        AppSpacing.lg,
                        AppSpacing.marginMobile,
                        AppSpacing.md,
                      ),
                      child: SectionHeader(title: categoryName),
                    ));
                    columnChildren.add(Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.marginMobile),
                      child: Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: products.map((product) {
                          return SizedBox(
                            width: cardWidth,
                            child: GestureDetector(
                              onTap: () => context.push(
                                  '${RoutePaths.productDetails}/${product.id}',
                                  extra: product),
                              child: QuickerXCard(
                                product: product,
                                onToggleWishlist: () => ref
                                    .read(homeFeedProvider.notifier)
                                    .toggleWishlist(product.id),
                                onAddToCart: () async {
                                  await ref
                                      .read(cartControllerProvider.notifier)
                                      .addProduct(
                                        product,
                                        shopId: feed.hub.id,
                                        shopName: feed.hub.name,
                                      );
                                },
                                onRemoveFromCart: () => ref
                                    .read(cartControllerProvider.notifier)
                                    .decrementProduct(product.id),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ));
                  });
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: columnChildren,
                    ),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: ProductGridShimmer()),
                error: (error, _) => SliverToBoxAdapter(
                  child: AppErrorView(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(homeFeedProvider),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: SizedBox(height: cartItemCount > 0 ? 120 : 100)),
            ],
          ),
        ),
      ),
    );
  }

  String _greetingTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
