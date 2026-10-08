import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/price_summary_card.dart';
import '../../address/application/address_controller.dart';
import '../../coupons/application/coupon_controller.dart';
import '../../cart/application/cart_controller.dart';
import '../../payment/application/payment_controller.dart';
import '../../payment/domain/models/payment_method_model.dart';
import '../application/checkout_controller.dart';

/// No Stitch design exists for this screen — built to match the app's
/// token system per the PRD's Checkout spec: delivery address, delivery
/// slot (instant/scheduled), order notes, coupon, platform fee, delivery
/// charge, tax, grand total, payment method, ETA, place order, premium
/// sticky bottom summary.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressController = ref.watch(addressListControllerProvider.notifier);
    ref.watch(addressListControllerProvider); // ensures rebuild once addresses load
    final defaultAddress = addressController.defaultAddress;
    final slotsAsync = ref.watch(deliverySlotsProvider);
    final selectedSlotId = ref.watch(selectedDeliverySlotIdProvider);
    final summary = ref.read(cartPriceSummaryProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final selectedPayment = ref.watch(selectedPaymentMethodProvider);
    final placeOrderState = ref.watch(placeOrderControllerProvider);

    ref.listen<PlaceOrderState>(placeOrderControllerProvider, (previous, next) {
      if (next.status == PlaceOrderStatus.success && next.order != null) {
        context.go(RoutePaths.orderSuccess, extra: next.order);
      } else if (next.status == PlaceOrderStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, 160),
        children: [
          _SectionCard(
            title: 'Delivery Address',
            trailing: TextButton(
              onPressed: () => context.push(RoutePaths.addressList),
              child: const Text('Change'),
            ),
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
                onChanged: (value) => ref.read(selectedDeliverySlotIdProvider.notifier).state = value!,
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
            title: 'Order Notes',
            child: TextField(
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Add instructions for delivery (optional)'),
              onChanged: (value) => ref.read(orderNotesProvider.notifier).state = value,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Payment Method',
            trailing: TextButton(onPressed: () => context.push(RoutePaths.paymentMethod), child: const Text('Change')),
            child: Text(
              kPaymentMethodOptions.firstWhere((o) => o.type == selectedPayment).label,
              style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PriceSummaryCard(summary: summary, appliedCoupon: appliedCoupon),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    selectedSlotId == 'instant' ? 'Estimated delivery: 18 mins' : 'Scheduled delivery selected',
                    style: AppTypography.labelLg(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: placeOrderState.status == PlaceOrderStatus.placing || defaultAddress == null
                      ? null
                      : () => ref.read(placeOrderControllerProvider.notifier).placeOrder(),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
                  child: placeOrderState.status == PlaceOrderStatus.placing
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
