import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Sticky bottom bar shown on Restaurant Details once items are in the
/// cart: "N items • ₹total" + "View Cart" CTA — the same shared-element
/// jumping-off point Swiggy/Zomato use before checkout.
class StickyRestaurantCartBar extends StatelessWidget {
  const StickyRestaurantCartBar({super.key, required this.itemCount, required this.total, required this.onViewCart});
  final int itemCount;
  final double total;
  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, 0, AppSpacing.marginMobile, AppSpacing.sm),
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.base),
          elevation: 6,
          child: InkWell(
            onTap: onViewCart,
            borderRadius: BorderRadius.circular(AppRadius.base),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Text('$itemCount item${itemCount > 1 ? 's' : ''} • ₹${total.toStringAsFixed(0)}', style: AppTypography.labelLg(color: Colors.white)),
                  const Spacer(),
                  Text('View Cart', style: AppTypography.labelLg(color: Colors.white)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
