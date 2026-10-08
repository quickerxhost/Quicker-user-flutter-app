import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/restaurant_card.dart';
import '../../../core/widgets/search_and_nav_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/application/cart_controller.dart';
import '../application/restaurant_list_controller.dart';

/// Matches Stitch `restaurants_quickerx`: search + voice search, filter/sort
/// row, banner slider, "Nearby Restaurants" grid with rating/distance/ETA/
/// free-delivery badges, pagination.
class RestaurantHomeScreen extends ConsumerStatefulWidget {
  const RestaurantHomeScreen({super.key});

  @override
  ConsumerState<RestaurantHomeScreen> createState() =>
      _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends ConsumerState<RestaurantHomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(restaurantListControllerProvider.notifier).loadMore();
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
    final state = ref.watch(restaurantListControllerProvider);
    final controller = ref.read(restaurantListControllerProvider.notifier);
    final restaurants = state.filteredSorted;
    final cartItemCount = ref.watch(cartItemCountProvider);

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
          onRefresh: controller.loadFirstPage,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile,
                      AppSpacing.md, AppSpacing.marginMobile, 0),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('Restaurants Near You',
                              style: AppTypography.headlineLgMobile()
                                  .copyWith(fontSize: 24))),
                      IconButton(
                          onPressed: () =>
                              context.push(RoutePaths.restaurantOrders),
                          icon: const Icon(Icons.receipt_long_outlined)),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile,
                      AppSpacing.sm, AppSpacing.marginMobile, 0),
                  child: AppSearchBar(
                    hintText: 'Search restaurants or food',
                    readOnly: true,
                    onTap: () => context.push(RoutePaths.restaurantSearch),
                    onVoiceTap: () => context.push(RoutePaths.voiceSearch),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.marginMobile),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Fast Delivery',
                        icon: Icons.bolt_rounded,
                        selected: state.fastDeliveryOnly,
                        onSelected: controller.toggleFastDelivery,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pure Veg',
                        icon: Icons.eco_outlined,
                        selected: state.pureVegOnly,
                        onSelected: controller.togglePureVeg,
                      ),
                      const SizedBox(width: 8),
                      _SortButton(
                          current: state.sort, onChanged: controller.setSort),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile),
                  child: Text('Nearby Restaurants',
                      style: AppTypography.titleLg().copyWith(fontSize: 17)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
              if (state.isInitialLoading)
                const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(AppSpacing.marginMobile),
                        child: Center(child: CircularProgressIndicator())))
              else if (state.errorMessage != null && restaurants.isEmpty)
                SliverToBoxAdapter(
                    child: AppErrorView(
                        message: state.errorMessage!,
                        onRetry: controller.loadFirstPage))
              else if (restaurants.isEmpty)
                const SliverToBoxAdapter(
                    child: EmptyView(
                        icon: Icons.storefront_outlined,
                        title: 'No restaurants found',
                        message: 'Try adjusting your filters.'))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile),
                  sliver: SliverList.separated(
                    itemCount: restaurants.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, index) {
                      if (index >= restaurants.length) {
                        return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)));
                      }
                      final restaurant = restaurants[index];
                      return RestaurantCard(
                        restaurant: restaurant,
                        onTap: () => context.push(
                            '${RoutePaths.restaurantDetails}/${restaurant.id}'),
                      );
                    },
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
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onSelected});
  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon,
          size: 16, color: selected ? Colors.white : AppColors.primary),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      labelStyle: AppTypography.labelLg(
          color: selected ? Colors.white : AppColors.onSurfaceVariant),
      backgroundColor: AppColors.surfaceContainerLow,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full)),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.current, required this.onChanged});
  final RestaurantSort current;
  final ValueChanged<RestaurantSort> onChanged;

  String _label(RestaurantSort sort) => switch (sort) {
        RestaurantSort.relevance => 'Sort',
        RestaurantSort.ratingHighToLow => 'Rating',
        RestaurantSort.deliveryTime => 'Delivery Time',
        RestaurantSort.costLowToHigh => 'Cost: Low to High',
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RestaurantSort>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base)),
      itemBuilder: (context) => RestaurantSort.values
          .map((sort) => PopupMenuItem(value: sort, child: Text(_label(sort))))
          .toList(),
      child: Chip(
        label: Text(_label(current)),
        avatar: const Icon(Icons.swap_vert_rounded,
            size: 16, color: AppColors.primary),
        backgroundColor: AppColors.surfaceContainerLow,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full)),
      ),
    );
  }
}
