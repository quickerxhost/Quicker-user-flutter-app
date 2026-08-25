import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/food_card.dart';
import '../../../core/widgets/menu_category_tabs.dart';
import '../../../core/widgets/rating_and_review_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/sticky_restaurant_cart_bar.dart';
import '../../restaurant_cart/application/restaurant_cart_controller.dart';
import '../../restaurant_reviews/application/restaurant_reviews_controller.dart';
import '../../restaurants/domain/models/restaurant_model.dart';
import '../application/restaurant_menu_controller.dart';
import '../domain/models/food_item_model.dart';

/// Matches Stitch `the_spice_hub_menu`: hero banner, restaurant info
/// (rating, distance, ETA, opening hours, tags), sticky menu-category
/// tabs, search-food field, menu list with ADD/customize controls,
/// restaurant info (license/FSSAI/address), reviews preview, sticky cart bar.
class RestaurantDetailsScreen extends ConsumerWidget {
  const RestaurantDetailsScreen({super.key, required this.restaurantId});
  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantDetailProvider(restaurantId));
    final menuAsync = ref.watch(restaurantMenuProvider(restaurantId));
    final cart = ref.watch(restaurantCartControllerProvider);

    return Scaffold(
      body: restaurantAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => AppErrorView(message: error.toString(), onRetry: () => ref.invalidate(restaurantDetailProvider(restaurantId))),
        data: (restaurant) => menuAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => AppErrorView(message: error.toString(), onRetry: () => ref.invalidate(restaurantMenuProvider(restaurantId))),
          data: (categories) => _DetailsBody(restaurant: restaurant, categories: categories),
        ),
      ),
      bottomNavigationBar: cart.restaurantId == restaurantId && cart.items.isNotEmpty
          ? StickyRestaurantCartBar(
              itemCount: cart.totalItemCount,
              total: cart.itemTotal,
              onViewCart: () => context.push(RoutePaths.restaurantCart),
            )
          : null,
    );
  }
}

class _DetailsBody extends ConsumerStatefulWidget {
  const _DetailsBody({required this.restaurant, required this.categories});
  final RestaurantModel restaurant;
  final List<MenuCategoryModel> categories;

  @override
  ConsumerState<_DetailsBody> createState() => _DetailsBodyState();
}

class _DetailsBodyState extends ConsumerState<_DetailsBody> {
  final _searchController = TextEditingController();
  final Map<String, GlobalKey> _sectionKeys = {};
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (final c in widget.categories) {
      _sectionKeys[c.id] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(String categoryId) {
    ref.read(activeMenuCategoryProvider(widget.restaurant.id).notifier).state = categoryId;
    final key = _sectionKeys[categoryId];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: 0.08);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final searchQuery = ref.watch(menuSearchQueryProvider(restaurant.id));
    final activeCategory = ref.watch(activeMenuCategoryProvider(restaurant.id)) ?? (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    final reviewsAsync = ref.watch(restaurantReviewsProvider(restaurant.id));
    final cart = ref.watch(restaurantCartControllerProvider);
    final cartController = ref.read(restaurantCartControllerProvider.notifier);

    final filteredCategories = searchQuery.isEmpty
        ? widget.categories
        : widget.categories
            .map((c) => MenuCategoryModel(id: c.id, title: c.title, items: c.items.where((i) => i.name.toLowerCase().contains(searchQuery.toLowerCase())).toList()))
            .where((c) => c.items.isNotEmpty)
            .toList();

    int quantityFor(String foodId) {
      if (cart.restaurantId != restaurant.id) return 0;
      return cart.items.where((i) => i.food.id == foodId).fold(0, (sum, i) => sum + i.quantity);
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.surface,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const CircleAvatar(backgroundColor: Colors.black38, child: Icon(Icons.arrow_back_rounded, color: Colors.white)),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primaryContainer, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: const Center(child: Icon(Icons.restaurant_rounded, color: Colors.white24, size: 72)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(restaurant.name, style: AppTypography.headlineLgMobile().copyWith(fontSize: 24))),
                    RatingWidget(rating: restaurant.rating, reviewCount: restaurant.reviewCount),
                  ],
                ),
                const SizedBox(height: 4),
                Text(restaurant.cuisineTags, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(icon: Icons.schedule_rounded, label: '${restaurant.etaMinutes} mins'),
                    _InfoChip(icon: Icons.location_on_outlined, label: '${restaurant.distanceKm.toStringAsFixed(1)} km'),
                    _InfoChip(icon: Icons.access_time_rounded, label: restaurant.openingHours),
                    if (restaurant.purity == FoodPurity.pureVeg) const _InfoChip(icon: Icons.eco_outlined, label: 'Pure Veg'),
                    if (restaurant.freeDelivery) const _InfoChip(icon: Icons.local_shipping_outlined, label: 'Free Delivery'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => ref.read(menuSearchQueryProvider(restaurant.id).notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Search for dishes',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.base), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (searchQuery.isEmpty)
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyTabsHeaderDelegate(
              child: MenuCategoryTabs(
                categories: widget.categories.map((c) => (id: c.id, title: c.title)).toList(),
                activeId: activeCategory,
                onSelect: _scrollToCategory,
              ),
            ),
          ),
        for (final category in filteredCategories) ...[
          SliverToBoxAdapter(
            child: Padding(
              key: _sectionKeys[category.id] ?? GlobalKey(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.lg, AppSpacing.marginMobile, 0),
              child: Text('${category.title} (${category.items.length})', style: AppTypography.titleLg().copyWith(fontSize: 17)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            sliver: SliverList.separated(
              itemCount: category.items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final food = category.items[index];
                return FoodCard(
                  food: food,
                  quantity: quantityFor(food.id),
                  onTap: () => context.push('${RoutePaths.foodDetails}/${food.id}'),
                  onAdd: () {
                    if (food.hasCustomization) {
                      context.push('${RoutePaths.foodDetails}/${food.id}');
                    } else {
                      _addSimple(context, restaurant, food, cartController);
                    }
                  },
                  onIncrement: () => _addSimple(context, restaurant, food, cartController),
                  onDecrement: () => _decrementFirstMatching(cartController, cart, food.id),
                );
              },
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.base)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Restaurant Info', style: AppTypography.titleLg().copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  if (restaurant.licenseFssai != null) Text('FSSAI License: ${restaurant.licenseFssai}', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(restaurant.address, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            child: Row(
              children: [
                Text('Ratings & Reviews', style: AppTypography.titleLg().copyWith(fontSize: 17)),
                const Spacer(),
                TextButton(onPressed: () => context.push('${RoutePaths.restaurantReviews}?restaurantId=${restaurant.id}'), child: const Text('See All')),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            child: reviewsAsync.when(
              data: (reviews) => Column(children: reviews.take(2).map((r) => RestaurantReviewCard(review: r)).toList()),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Future<void> _addSimple(BuildContext context, RestaurantModel restaurant, FoodItemModel food, RestaurantCartController cartController) async {
    if (cartController.wouldConflictWithRestaurant(restaurant.id)) {
      final shouldReplace = await _confirmReplaceCart(context);
      if (shouldReplace != true) return;
      await cartController.clearCart();
    }
    await cartController.addItem(food: food, restaurantName: restaurant.name);
  }

  Future<void> _decrementFirstMatching(RestaurantCartController controller, RestaurantCartState cart, String foodId) async {
    final match = cart.items.where((i) => i.food.id == foodId).toList();
    if (match.isEmpty) return;
    await controller.updateQuantity(match.first.id, match.first.quantity - 1);
  }

  Future<bool?> _confirmReplaceCart(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new order?'),
        content: const Text('Your cart has items from another restaurant. Adding this item will clear your current cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear Cart')),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
