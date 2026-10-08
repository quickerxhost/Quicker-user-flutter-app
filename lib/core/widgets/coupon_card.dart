import 'package:flutter/material.dart';
import '../../features/coupons/domain/models/coupon_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Dashed-edge style coupon card (title, description, min-order note) with
/// Copy + Apply actions, used on the Coupons screen.
class CouponCard extends StatelessWidget {
  const CouponCard({
    super.key,
    required this.coupon,
    this.applied = false,
    this.onApply,
    this.onRemove,
    this.onCopy,
  });

  final CouponModel coupon;
  final bool applied;
  final VoidCallback? onApply;
  final VoidCallback? onRemove;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: applied ? AppColors.primary : AppColors.outlineVariant, width: applied ? 1.5 : 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: const Icon(Icons.sell_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(coupon.title, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w700))),
                    if (coupon.isRecommended && !applied)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(AppRadius.sm)),
                        child: const Text('BEST', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(coupon.description, style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w400)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DottedCodePill(code: coupon.code, onTap: onCopy),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (applied)
                      TextButton(onPressed: onRemove, child: const Text('REMOVE'))
                    else
                      TextButton(onPressed: onApply, child: const Text('APPLY')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed-border coupon-code pill with a copy icon.
class DottedCodePill extends StatelessWidget {
  const DottedCodePill({super.key, required this.code, this.onTap});
  final String code;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: AppColors.surfaceContainerLow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(code, style: AppTypography.labelLg().copyWith(letterSpacing: 1), overflow: TextOverflow.ellipsis)),
            if (onTap != null) ...[const SizedBox(width: 6), const Icon(Icons.copy_rounded, size: 14, color: AppColors.onSurfaceVariant)],
          ],
        ),
      ),
    );
  }
}
