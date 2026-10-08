import 'package:flutter/material.dart';
import '../../features/coupons/domain/models/coupon_model.dart';
import '../../features/restaurant_cart/domain/models/restaurant_cart_line_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// "Bill Summary" card matching Stitch `food_checkout`: item total,
/// delivery charge, packing charge, taxes, coupon discount, grand total.
class RestaurantBillSummary extends StatelessWidget {
  const RestaurantBillSummary({super.key, required this.summary, this.appliedCoupon});
  final RestaurantCartBillSummary summary;
  final CouponModel? appliedCoupon;

  @override
  Widget build(BuildContext context) {
    final couponDiscount = appliedCoupon?.discountFor(summary.itemTotal) ?? 0;
    final grandTotal = summary.grandTotal - couponDiscount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.base)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bill Summary', style: AppTypography.titleLg().copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          _Row(label: 'Item Total', value: summary.itemTotal),
          _Row(label: 'Delivery Charge', value: summary.deliveryCharge),
          _Row(label: 'Packing Charge', value: summary.packingCharge),
          if (summary.taxes > 0) _Row(label: 'Taxes & Charges', value: summary.taxes),
          if (appliedCoupon != null && couponDiscount > 0) _Row(label: 'Coupon (${appliedCoupon!.code})', value: -couponDiscount, isDiscount: true),
          if (summary.coinsDiscount > 0) const _Row(label: 'QX Coins Applied', value: 0, isDiscount: true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          _Row(label: 'To Pay', value: grandTotal, isTotal: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.isDiscount = false, this.isTotal = false});
  final String label;
  final double value;
  final bool isDiscount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w700, fontSize: 16)
        : AppTypography.bodyMd(color: AppColors.onSurfaceVariant);
    final valueColor = isDiscount ? AppColors.primary : (isTotal ? AppColors.onSurface : AppColors.onSurfaceVariant);
    final sign = value < 0 ? '-' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('$sign₹${value.abs().toStringAsFixed(0)}', style: style.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
