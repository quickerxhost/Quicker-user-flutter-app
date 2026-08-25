import 'package:flutter/material.dart';
import '../../features/cart/domain/models/cart_item_model.dart';
import '../../features/coupons/domain/models/coupon_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// "Order Summary" card — subtotal, discount, platform fee, delivery
/// charge, coupon discount, grand total. Used on both Cart and Checkout so
/// the numbers are guaranteed to match between the two screens.
class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({super.key, required this.summary, this.appliedCoupon});

  final CartPriceSummary summary;
  final CouponModel? appliedCoupon;

  @override
  Widget build(BuildContext context) {
    final couponDiscount = appliedCoupon?.discountFor(summary.subtotal) ?? 0;
    final grandTotal = summary.grandTotal - couponDiscount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.base)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bill Details', style: AppTypography.titleLg().copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          _Row(label: 'Item Total', value: summary.subtotal),
          if (summary.discount > 0) _Row(label: 'Item Discount', value: -summary.discount, isDiscount: true),
          if (appliedCoupon != null && couponDiscount > 0)
            _Row(label: 'Coupon (${appliedCoupon!.code})', value: -couponDiscount, isDiscount: true),
          _Row(label: 'Platform Fee', value: summary.platformFee),
          _Row(label: 'Delivery Charge', value: summary.deliveryCharge),
          if (summary.tax > 0) _Row(label: 'Tax', value: summary.tax),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          _Row(label: 'Grand Total', value: grandTotal, isTotal: true),
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
        ? AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w700)
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
