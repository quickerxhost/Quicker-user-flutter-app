import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../features/restaurants/domain/models/restaurant_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Restaurant card matching the Stitch `restaurants_quickerx` design:
/// full-width image with rating chip + free-delivery/bestseller badges,
/// name, cuisine tags, and a meta row (ETA • distance • cost for two).
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({super.key, required this.restaurant, this.onTap});
  final RestaurantModel restaurant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.image),
                    child: CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surfaceContainerHigh),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(Icons.restaurant_rounded, color: AppColors.outline, size: 32),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      if (restaurant.isBestseller) const _Tag(label: 'BESTSELLER', color: AppColors.secondaryContainer),
                      if (restaurant.isNew) const _Tag(label: 'NEW', color: AppColors.primary),
                    ],
                  ),
                ),
                if (restaurant.freeDelivery)
                  const Positioned(
                    bottom: 8,
                    left: 8,
                    child: _Tag(label: 'FREE DELIVERY', color: AppColors.tertiary),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(restaurant.rating.toStringAsFixed(1), style: AppTypography.labelLg(color: Colors.white).copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(restaurant.name, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 2),
          Text(restaurant.cuisineTags, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w400)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 13, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 3),
              Text('${restaurant.etaMinutes} mins', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontSize: 12)),
              const SizedBox(width: 10),
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 3),
              Text('${restaurant.distanceKm.toStringAsFixed(1)} km', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontSize: 12)),
              const Spacer(),
              Text('₹${restaurant.costForTwo.toStringAsFixed(0)} for two', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(label, style: AppTypography.labelLg(color: Colors.white).copyWith(fontSize: 10)),
    );
  }
}
