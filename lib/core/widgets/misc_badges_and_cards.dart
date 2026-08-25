import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Small rounded chip for offers/badges ("FEST50", "Free Delivery").
class OfferChip extends StatelessWidget {
  const OfferChip({super.key, required this.label, this.icon, this.color = AppColors.secondaryContainer});
  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(label, style: AppTypography.labelLg(color: color).copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Small colored badge for product cards/detail ("20% OFF", "Out of Stock").
class ProductBadge extends StatelessWidget {
  const ProductBadge({super.key, required this.label, this.color = AppColors.secondaryContainer, this.textColor = Colors.white});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(label, style: AppTypography.labelLg(color: textColor).copyWith(fontSize: 11)),
    );
  }
}

/// Card showing ETA + hub name — used on Product Details and the Cart's
/// per-shop group header.
class DeliveryTimeCard extends StatelessWidget {
  const DeliveryTimeCard({super.key, required this.etaLabel, required this.hubName});
  final String etaLabel;
  final String hubName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(AppRadius.base)),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery in $etaLabel', style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
                Text('from $hubName', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
