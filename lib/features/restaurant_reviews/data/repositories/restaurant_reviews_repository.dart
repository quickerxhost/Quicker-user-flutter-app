import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/restaurant_review_model.dart';

/// `ApiEndpoints.restaurantReviews` / `submitReview` are currently BLANK —
/// falls back to fixture reviews for reading, and [submitReview] just
/// echoes back a locally-constructed review so the "Write Review" flow is
/// testable end-to-end before the backend exists.
class RestaurantReviewsRepository {
  RestaurantReviewsRepository(this._client);
  final DioClient _client;

  Future<ApiResult<List<RestaurantReviewModel>>> getReviews(String restaurantId) async {
    if (ApiEndpoints.restaurantReviews.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      return ApiResult.success(_fixtureReviews());
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.restaurantReviews, queryParameters: {'restaurant_id': restaurantId});
        return (response.data as List).cast<Map<String, dynamic>>();
      });
      return ApiResult.success(data.map(RestaurantReviewModel.fromJson).toList());
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  Future<ApiResult<RestaurantReviewModel>> submitReview({
    required String restaurantId,
    required double restaurantRating,
    required double foodRating,
    required double deliveryRating,
    required String comment,
    List<String> imageUrls = const [],
  }) async {
    if (ApiEndpoints.submitReview.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      return ApiResult.success(RestaurantReviewModel(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        authorName: 'You',
        restaurantRating: restaurantRating,
        foodRating: foodRating,
        deliveryRating: deliveryRating,
        comment: comment,
        imageUrls: imageUrls,
        date: DateTime.now(),
      ));
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.post(ApiEndpoints.submitReview, data: {
          'restaurant_id': restaurantId,
          'restaurant_rating': restaurantRating,
          'food_rating': foodRating,
          'delivery_rating': deliveryRating,
          'comment': comment,
          'image_urls': imageUrls,
        });
        return response.data as Map<String, dynamic>;
      });
      return ApiResult.success(RestaurantReviewModel.fromJson(data));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  List<RestaurantReviewModel> _fixtureReviews() {
    final now = DateTime.now();
    return [
      RestaurantReviewModel(
        id: 'r1',
        authorName: 'Ananya R.',
        restaurantRating: 5,
        foodRating: 5,
        deliveryRating: 4.5,
        comment: 'The Galouti Kebab was outstanding — melt-in-mouth texture and the smoke aroma was authentic.',
        date: now.subtract(const Duration(days: 1)),
        helpfulCount: 24,
      ),
      RestaurantReviewModel(
        id: 'r2',
        authorName: 'Vikram S.',
        restaurantRating: 4.5,
        foodRating: 4,
        deliveryRating: 5,
        comment: 'Delivery was super quick, food arrived hot. Paneer Tikka could use a bit more spice.',
        date: now.subtract(const Duration(days: 4)),
        helpfulCount: 11,
      ),
      RestaurantReviewModel(
        id: 'r3',
        authorName: 'Meera K.',
        restaurantRating: 5,
        foodRating: 5,
        deliveryRating: 4,
        comment: 'Best biryani in the neighborhood, hands down. Ordering again this weekend.',
        date: now.subtract(const Duration(days: 9)),
        helpfulCount: 38,
      ),
    ];
  }
}
