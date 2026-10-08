import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/state_views.dart';
import '../../coupons/application/coupon_controller.dart';
import '../application/restaurant_cart_controller.dart';
import '../domain/models/restaurant_cart_line_item.dart';

/// Item-list portion of Stitch `food_checkout` (top "Your Order" section) —
/// the full one-page address/bill/payment view from that design is built
/// as the separate Restaurant Checkout screen per the PRD's split
/// Cart/Checkout structure; "Proceed to Checkout" here leads into it.
class RestaurantCartScreen extends ConsumerWidget {
  const RestaurantCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(restaurantCartControllerProvider);
    final controller = ref.read(restaurantCartControllerProvider.notifier);
    final appliedCoupon = ref.watch(appliedCouponProvider);

    return Scaffold(
      appBar: AppBar(title: Text(cart.restaurantName ?? 'Your Order')),
      body: cart.isLoading
          ? const LoadingView()
          : cart.items.isEmpty
              ? EmptyView(
                  icon: Icons.ramen_dining_outlined,
                  title: 'Your cart is empty',
                  message: 'Add some delicious food to get started!',
                  action: ElevatedButton(onPressed: () => context.go(RoutePaths.restaurantHome), child: const Text('Browse Restaurants')),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, 160),
                  children: [
                    Container(
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Column(
                        children: cart.items.map((item) => _CartLine(item: item, controller: controller)).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.base)),
                      child: GestureDetector(
                        onTap: () => context.push(RoutePaths.coupons),
                        child: Row(
                          children: [
                            const Icon(Icons.sell_outlined, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                appliedCoupon != null ? '${appliedCoupon.code} applied' : 'Apply Coupon',
                                style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.marginMobile),
                decoration: const BoxDecoration(color: AppColors.surfaceContainerLowest, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))]),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${cart.itemTotal.toStringAsFixed(0)}', style: AppTypography.titleLg()),
                          Text('${cart.totalItemCount} items', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    ElevatedButton(onPressed: () => context.push(RoutePaths.restaurantCheckout), child: const Text('Proceed to Checkout')),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.item, required this.controller});
  final RestaurantCartLineItem item;
  final RestaurantCartController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: CachedNetworkImage(
              imageUrl: item.food.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(width: 56, height: 56, color: AppColors.surfaceContainerHigh, child: const Icon(Icons.fastfood_rounded, color: AppColors.outline, size: 18)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.food.name, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
                if (item.selectedAddOnLabels.isNotEmpty)
                  Text(item.selectedAddOnLabels.join(', '), style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                Text('₹${item.unitPrice.toStringAsFixed(0)}', style: AppTypography.labelLg()),
              ],
            ),
          ),
          QuantityStepper(
            compact: true,
            quantity: item.quantity,
            onIncrement: () => controller.updateQuantity(item.id, item.quantity + 1),
            onDecrement: () => controller.updateQuantity(item.id, item.quantity - 1),
          ),
        ],
      ),
    );
  }
}
