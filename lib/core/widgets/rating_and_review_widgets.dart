import 'package:flutter/material.dart';
import '../../features/restaurant_reviews/domain/models/restaurant_review_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Compact star-rating pill (e.g. "4.8 ★ (1.2k)") reused on restaurant
/// cards, details header, and review summaries.
class RatingWidget extends StatelessWidget {
  const RatingWidget({super.key, required this.rating, this.reviewCount, this.compact = false});
  final double rating;
  final int? reviewCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(color: const Color(0xFF0F8A0F), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: compact ? 12 : 14, color: Colors.white),
          const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1), style: AppTypography.labelLg(color: Colors.white).copyWith(fontSize: compact ? 11 : 12)),
          if (reviewCount != null) ...[
            const SizedBox(width: 3),
            Text('(${_formatCount(reviewCount!)})', style: AppTypography.labelLg(color: Colors.white).copyWith(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w400)),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) => count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';
}

/// Star row for input (Write Review) — tap to set [rating].
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({super.key, required this.rating, required this.onChanged, this.size = 28});
  final double rating;
  final ValueChanged<double> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        return GestureDetector(
          onTap: () => onChanged(starValue.toDouble()),
          child: Icon(
            starValue <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: AppColors.secondaryContainer,
          ),
        );
      }),
    );
  }
}

/// Review card showing the three sub-ratings (restaurant/food/delivery),
/// comment, optional photos, and a "Helpful" count — used on the
/// Restaurant Reviews screen and Restaurant Details' reviews preview.
class RestaurantReviewCard extends StatelessWidget {
  const RestaurantReviewCard({super.key, required this.review});
  final RestaurantReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.base)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: AppColors.primaryFixed, child: Text(review.authorName.isNotEmpty ? review.authorName[0] : '?', style: AppTypography.labelLg(color: AppColors.primary))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(review.authorName, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600))),
              RatingWidget(rating: review.restaurantRating, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(review.comment, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _MiniRating(label: 'Food', value: review.foodRating),
              const SizedBox(width: AppSpacing.md),
              _MiniRating(label: 'Delivery', value: review.deliveryRating),
              const Spacer(),
              const Icon(Icons.thumb_up_outlined, size: 14, color: AppColors.outline),
              const SizedBox(width: 4),
              Text('${review.helpfulCount}', style: AppTypography.labelLg(color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniRating extends StatelessWidget {
  const _MiniRating({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: AppTypography.labelLg(color: AppColors.outline).copyWith(fontSize: 11)),
        const Icon(Icons.star_rounded, size: 12, color: AppColors.secondaryContainer),
        Text(value.toStringAsFixed(1), style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontSize: 11)),
      ],
    );
  }
}
