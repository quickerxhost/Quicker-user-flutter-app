import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../features/home/domain/models/banner_model.dart';
import '../../features/home/domain/models/delivery_hub_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Full-bleed rounded promo banner ("Limited Offer 🍔 Food Delivery",
/// "Festival Delights Flat 50% OFF"...).
class OfferBanner extends StatelessWidget {
  const OfferBanner({super.key, required this.banner, this.onTap});
  final BannerModel banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: const LinearGradient(
            colors: [AppColors.primaryContainer, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (banner.imageUrl.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: CachedNetworkImage(imageUrl: banner.imageUrl, fit: BoxFit.cover),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: AppTypography.titleLg(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle,
                    style: AppTypography.bodyMd(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  if (banner.code != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text('CODE: ${banner.code}', style: AppTypography.labelLg(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "CURRENT HUB" card shown at the top of Home, with ETA + shop count chips.
class DeliveryHubCard extends StatelessWidget {
  const DeliveryHubCard({super.key, required this.hub});
  final DeliveryHubModel hub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('CURRENT HUB', style: AppTypography.labelLg(color: AppColors.onPrimaryFixedVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Text('📍 ${hub.name}', style: AppTypography.titleLg()),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _StatChip(icon: Icons.schedule, label: '${hub.etaMinutes} Minutes'),
              const SizedBox(width: 8),
              _StatChip(icon: Icons.storefront, label: '${hub.shopCount} Shops'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.onPrimaryFixedVariant),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelLg(color: AppColors.onPrimaryFixedVariant).copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
