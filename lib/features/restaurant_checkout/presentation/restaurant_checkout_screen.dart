import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/restaurant_bill_summary.dart';
import '../../address/application/address_controller.dart';
import '../../coupons/application/coupon_controller.dart';
import '../../payment/application/payment_controller.dart';
import '../../payment/domain/models/payment_method_model.dart';
import '../../restaurant_cart/application/restaurant_cart_controller.dart';
import '../../restaurant_cart/domain/models/restaurant_cart_line_item.dart';
import '../application/restaurant_checkout_controller.dart';

/// Matches Stitch `food_checkout`: delivery address, delivery slot
/// (instant/scheduled), order instructions, coupon, bill summary
/// (item total/delivery/packing/taxes/grand total), payment method strip,
/// sticky "Place Order" bottom bar.
class RestaurantCheckoutScreen extends ConsumerWidget {
  const RestaurantCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(restaurantCartControllerProvider);
    final defaultAddress = ref.watch(addressListControllerProvider.notifier).defaultAddress;
    ref.watch(addressListControllerProvider);
    final slotsAsync = ref.watch(restaurantDeliverySlotsProvider);
    final selectedSlotId = ref.watch(restaurantSelectedSlotIdProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final selectedPayment = ref.watch(selectedPaymentMethodProvider);
    final placeOrderState = ref.watch(restaurantPlaceOrderControllerProvider);

    final summary = RestaurantCartBillSummary(itemTotal: cart.itemTotal);

    ref.listen<RestaurantPlaceOrderState>(restaurantPlaceOrderControllerProvider, (previous, next) {
      if (next.status == RestaurantPlaceOrderStatus.success && next.order != null) {
        context.go(RoutePaths.restaurantOrderSuccess, extra: next.order);
      } else if (next.status == RestaurantPlaceOrderStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, 160),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.base)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Order', style: AppTypography.titleLg().copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                ...cart.items.map((item) => _OrderLineRecap(item: item)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Delivery Address',
            trailing: TextButton(onPressed: () => context.push(RoutePaths.addressList), child: const Text('Change')),
            child: defaultAddress == null
                ? OutlinedButton(onPressed: () => context.push(RoutePaths.addAddress), child: const Text('Add Delivery Address'))
                : Text(defaultAddress.fullLine, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Delivery Slot',
            child: slotsAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const Text('Could not load delivery slots.'),
              data: (slots) => RadioGroup<String>(
                groupValue: selectedSlotId,
                onChanged: (value) => ref.read(restaurantSelectedSlotIdProvider.notifier).state = value!,
                child: Column(
                  children: slots
                      .map((slot) => RadioListTile<String>(
                            value: slot.id,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primary,
                            title: Text(slot.label),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Order Instructions',
            child: TextField(
              maxLines: 2,
              decoration: const InputDecoration(hintText: "e.g. Don't ring the bell, call on arrival"),
              onChanged: (value) => ref.read(restaurantOrderInstructionsProvider.notifier).state = value,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Payment Method',
            trailing: TextButton(onPressed: () => context.push(RoutePaths.restaurantPayment), child: const Text('Change')),
            child: Text(
              kPaymentMethodOptions.firstWhere((o) => o.type == selectedPayment).label,
              style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RestaurantBillSummary(summary: summary, appliedCoupon: appliedCoupon),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          decoration: const BoxDecoration(color: AppColors.surfaceContainerLowest, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    selectedSlotId == 'instant' ? 'Estimated arrival: 25-30 mins' : 'Scheduled delivery selected',
                    style: AppTypography.labelLg(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: placeOrderState.status == RestaurantPlaceOrderStatus.placing || defaultAddress == null
                      ? null
                      : () => ref.read(restaurantPlaceOrderControllerProvider.notifier).placeOrder(),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
                  child: placeOrderState.status == RestaurantPlaceOrderStatus.placing
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Place Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderLineRecap extends StatelessWidget {
  const _OrderLineRecap({required this.item});
  final RestaurantCartLineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('${item.quantity}x', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 8),
          Expanded(child: Text(item.food.name, style: AppTypography.bodyMd())),
          Text('₹${item.lineTotal.toStringAsFixed(0)}', style: AppTypography.bodyMd()),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.base)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTypography.titleLg().copyWith(fontSize: 16))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
