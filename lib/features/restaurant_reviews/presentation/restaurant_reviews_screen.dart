import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/rating_and_review_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../application/restaurant_reviews_controller.dart';

/// No dedicated Stitch design exists for this screen — built to match the
/// app's token system per the PRD's Restaurant Reviews spec: write review
/// (separate restaurant/food/delivery ratings), upload images, helpful
/// reviews list.
class RestaurantReviewsScreen extends ConsumerWidget {
  const RestaurantReviewsScreen({super.key, required this.restaurantId});
  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(restaurantReviewsProvider(restaurantId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ratings & Reviews')),
      body: reviewsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => AppErrorView(message: error.toString(), onRetry: () => ref.invalidate(restaurantReviewsProvider(restaurantId))),
        data: (reviews) => ListView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            OutlinedButton.icon(
              onPressed: () => _showWriteReviewSheet(context, ref),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Write a Review'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (reviews.isEmpty)
              const EmptyView(icon: Icons.reviews_outlined, title: 'No reviews yet', message: 'Be the first to share your experience!')
            else
              ...reviews.map((r) => RestaurantReviewCard(review: r)),
          ],
        ),
      ),
    );
  }

  void _showWriteReviewSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md))),
      builder: (context) => _WriteReviewSheet(restaurantId: restaurantId),
    );
  }
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  const _WriteReviewSheet({required this.restaurantId});
  final String restaurantId;

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  double _restaurantRating = 0;
  double _foodRating = 0;
  double _deliveryRating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_restaurantRating == 0 || _foodRating == 0 || _deliveryRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please rate all three categories.')));
      return;
    }
    final ok = await ref.read(submitReviewControllerProvider.notifier).submit(
          restaurantId: widget.restaurantId,
          restaurantRating: _restaurantRating,
          foodRating: _foodRating,
          deliveryRating: _deliveryRating,
          comment: _commentController.text.trim(),
        );
    if (ok && mounted) {
      ref.invalidate(restaurantReviewsProvider(widget.restaurantId));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitReviewControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        top: AppSpacing.marginMobile,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.marginMobile,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate your experience', style: AppTypography.titleLg()),
          const SizedBox(height: AppSpacing.lg),
          _RatingRow(label: 'Restaurant', value: _restaurantRating, onChanged: (v) => setState(() => _restaurantRating = v)),
          _RatingRow(label: 'Food', value: _foodRating, onChanged: (v) => setState(() => _foodRating = v)),
          _RatingRow(label: 'Delivery', value: _deliveryRating, onChanged: (v) => setState(() => _deliveryRating = v)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Share details about your experience...'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image upload requires a backend storage endpoint.')),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Upload Photos'),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Submit Review',
            trailingIcon: null,
            isLoading: submitState.status == SubmitReviewStatus.submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
          StarRatingInput(rating: value, onChanged: onChanged, size: 24),
        ],
      ),
    );
  }
}
