import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/product_image_carousel.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/veg_non_veg_badge.dart';
import '../../restaurant_cart/application/restaurant_cart_controller.dart';
import '../../restaurant_menu/domain/models/food_item_model.dart';
import '../application/food_details_controller.dart';

/// No dedicated Stitch design exists for this screen (the menu-list "ADD"
/// button covers simple items) — built to match the app's token system
/// per the PRD's full Food Details spec: image gallery with Hero
/// animation + zoom, description, ingredients, nutrition, add-ons/spice
/// level customization, quantity, sticky add-to-cart.
class FoodDetailsScreen extends ConsumerWidget {
  const FoodDetailsScreen({super.key, required this.foodId});
  final String foodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodAsync = ref.watch(foodDetailProvider(foodId));

    return Scaffold(
      body: foodAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => AppErrorView(message: error.toString(), onRetry: () => ref.invalidate(foodDetailProvider(foodId))),
        data: (food) => _FoodDetailsBody(food: food),
      ),
    );
  }
}

class _FoodDetailsBody extends ConsumerWidget {
  const _FoodDetailsBody({required this.food});
  final FoodItemModel food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(foodQuantityProvider(food.id));
    final selections = ref.watch(selectedAddOnsControllerProvider(food.id));
    final selectionsController = ref.read(selectedAddOnsControllerProvider(food.id).notifier);
    final addOnsTotal = FoodCustomizationCalculator.addOnsTotal(food, selections);
    final unitPrice = food.price + addOnsTotal;

    final requiredGroupsSatisfied = food.addOnGroups
        .where((g) => g.required)
        .every((g) => (selections[g.id] ?? const {}).isNotEmpty);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.surface,
              pinned: true,
              leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.marginMobile),
                child: ProductImageCarousel(imageUrls: [food.imageUrl], heroTag: 'food-image-${food.id}'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        VegNonVegBadge(purity: food.purity),
                        const SizedBox(width: 8),
                        Expanded(child: Text(food.name, style: AppTypography.headlineLgMobile().copyWith(fontSize: 22))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('₹${unitPrice.toStringAsFixed(0)}', style: AppTypography.headlineLgMobile().copyWith(fontSize: 24)),
                        if (food.originalPrice != null) ...[
                          const SizedBox(width: 8),
                          Text('₹${food.originalPrice!.toStringAsFixed(0)}', style: AppTypography.bodyMd(color: AppColors.outline).copyWith(decoration: TextDecoration.lineThrough)),
                        ],
                        const Spacer(),
                        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${food.prepTimeMinutes} mins', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(food.description, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                    if (food.ingredients != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text('Ingredients', style: AppTypography.titleLg().copyWith(fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(food.ingredients!.join(', '), style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                    ],
                    if (food.nutrition != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text('Nutrition (per serving)', style: AppTypography.titleLg().copyWith(fontSize: 16)),
                      const SizedBox(height: 6),
                      ...food.nutrition!.entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                                Text(e.value, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )),
                    ],
                    for (final group in food.addOnGroups) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Text(group.title, style: AppTypography.titleLg().copyWith(fontSize: 16)),
                          if (group.required) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(AppRadius.sm)),
                              child: Text('Required', style: AppTypography.labelLg(color: AppColors.onErrorContainer).copyWith(fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (group.singleSelect)
                        RadioGroup<String>(
                          groupValue: (selections[group.id] ?? const {}).isEmpty ? null : (selections[group.id] ?? const {}).first,
                          onChanged: (value) {
                            if (value != null) selectionsController.selectSingle(group.id, value);
                          },
                          child: Column(
                            children: group.options
                                .map((option) => RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
                                      value: option.id,
                                      activeColor: AppColors.primary,
                                      title: Text(option.label),
                                      secondary: option.price > 0 ? Text('+₹${option.price.toStringAsFixed(0)}') : null,
                                    ))
                                .toList(),
                          ),
                        )
                      else
                        ...group.options.map((option) => CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: (selections[group.id] ?? const {}).contains(option.id),
                              activeColor: AppColors.primary,
                              title: Text(option.label),
                              secondary: option.price > 0 ? Text('+₹${option.price.toStringAsFixed(0)}') : null,
                              onChanged: (_) => selectionsController.toggleMulti(group.id, option.id),
                            )),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile, vertical: AppSpacing.sm),
          decoration: const BoxDecoration(color: AppColors.surfaceContainerLowest, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))]),
          child: Row(
            children: [
              QuantityStepper(
                quantity: quantity,
                onIncrement: () => ref.read(foodQuantityProvider(food.id).notifier).state = quantity + 1,
                onDecrement: () => ref.read(foodQuantityProvider(food.id).notifier).state = (quantity - 1).clamp(1, 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: !requiredGroupsSatisfied
                      ? null
                      : () async {
                          final cartController = ref.read(restaurantCartControllerProvider.notifier);
                          if (cartController.wouldConflictWithRestaurant(food.restaurantId)) {
                            final shouldReplace = await showDialog<bool>(
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
                            if (shouldReplace != true) return;
                            await cartController.clearCart();
                          }
                          await cartController.addItem(
                            food: food,
                            restaurantName: 'Restaurant',
                            quantity: quantity,
                            addOnLabels: FoodCustomizationCalculator.selectedLabels(food, selections),
                            addOnsTotal: addOnsTotal,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${food.name} to cart')));
                            context.pop();
                          }
                        },
                  child: Text('Add to Cart • ₹${(unitPrice * quantity).toStringAsFixed(0)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
