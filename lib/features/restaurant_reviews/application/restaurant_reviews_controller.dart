import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/repositories/restaurant_reviews_repository.dart';
import '../domain/models/restaurant_review_model.dart';

final restaurantReviewsRepositoryProvider = Provider<RestaurantReviewsRepository>((ref) {
  return RestaurantReviewsRepository(ref.watch(dioClientProvider));
});

final restaurantReviewsProvider = FutureProvider.family<List<RestaurantReviewModel>, String>((ref, restaurantId) async {
  final result = await ref.watch(restaurantReviewsRepositoryProvider).getReviews(restaurantId);
  return result.when(success: (v) => v, failure: (_) => const []);
});

enum SubmitReviewStatus { idle, submitting, success, error }

class SubmitReviewState {
  final SubmitReviewStatus status;
  final String? errorMessage;
  const SubmitReviewState({this.status = SubmitReviewStatus.idle, this.errorMessage});
}

final submitReviewControllerProvider =
    StateNotifierProvider.autoDispose<SubmitReviewController, SubmitReviewState>((ref) {
  return SubmitReviewController(ref.watch(restaurantReviewsRepositoryProvider));
});

class SubmitReviewController extends StateNotifier<SubmitReviewState> {
  SubmitReviewController(this._repository) : super(const SubmitReviewState());
  final RestaurantReviewsRepository _repository;

  Future<bool> submit({
    required String restaurantId,
    required double restaurantRating,
    required double foodRating,
    required double deliveryRating,
    required String comment,
  }) async {
    state = const SubmitReviewState(status: SubmitReviewStatus.submitting);
    final result = await _repository.submitReview(
      restaurantId: restaurantId,
      restaurantRating: restaurantRating,
      foodRating: foodRating,
      deliveryRating: deliveryRating,
      comment: comment,
    );
    return result.when(
      success: (_) {
        state = const SubmitReviewState(status: SubmitReviewStatus.success);
        return true;
      },
      failure: (e) {
        state = SubmitReviewState(status: SubmitReviewStatus.error, errorMessage: e.message);
        return false;
      },
    );
  }
}
