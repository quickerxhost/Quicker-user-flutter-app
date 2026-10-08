import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/coupon_model.dart';

/// `ApiEndpoints.coupons` / `applyCoupon` / `removeCoupon` are currently
/// BLANK — falls back to a fixture set (platform/shop/restaurant coupons)
/// until the backend contract is ready.
class CouponRepository {
  CouponRepository(this._client);
  final DioClient _client;

  Future<ApiResult<List<CouponModel>>> getAvailableCoupons() async {
    if (ApiEndpoints.coupons.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      return const ApiResult.success(_fixture);
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.coupons);
        return (response.data as List).cast<Map<String, dynamic>>();
      });
      return ApiResult.success(data.map(CouponModel.fromJson).toList());
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  /// Validates a coupon code against the (fixture or real) catalogue and
  /// returns it if valid for [orderValue].
  Future<ApiResult<CouponModel>> applyCoupon(String code, {required double orderValue}) async {
    if (ApiEndpoints.applyCoupon.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      final match = _fixture.where((c) => c.code.toUpperCase() == code.trim().toUpperCase()).toList();
      if (match.isEmpty) {
        return const ApiResult.failure(
          NetworkException(type: NetworkFailureType.validation, message: 'Invalid coupon code.'),
        );
      }
      if (orderValue < match.first.minOrderValue) {
        return ApiResult.failure(NetworkException(
          type: NetworkFailureType.validation,
          message: 'Add ₹${(match.first.minOrderValue - orderValue).toStringAsFixed(0)} more to use this coupon.',
        ));
      }
      return ApiResult.success(match.first);
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.post(ApiEndpoints.applyCoupon, data: {'code': code, 'order_value': orderValue});
        return response.data as Map<String, dynamic>;
      });
      return ApiResult.success(CouponModel.fromJson(data));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  static const _fixture = <CouponModel>[
    CouponModel(
      code: 'FIRST50',
      title: 'Flat ₹50 OFF',
      description: 'On your first order above ₹199',
      scope: CouponScope.platform,
      discountValue: 50,
      minOrderValue: 199,
      isRecommended: true,
    ),
    CouponModel(
      code: 'SAVE20',
      title: '20% OFF up to ₹100',
      description: 'On all grocery orders above ₹499',
      scope: CouponScope.platform,
      discountValue: 20,
      isPercent: true,
      maxDiscount: 100,
      minOrderValue: 499,
    ),
    CouponModel(
      code: 'SHOP10',
      title: '10% OFF at select shops',
      description: 'Valid at Jaystambh Hub partner stores',
      scope: CouponScope.shop,
      discountValue: 10,
      isPercent: true,
      maxDiscount: 60,
      minOrderValue: 149,
    ),
    CouponModel(
      code: 'FOODIE30',
      title: '₹30 OFF on restaurant orders',
      description: 'Minimum order ₹250',
      scope: CouponScope.restaurant,
      discountValue: 30,
      minOrderValue: 250,
    ),
  ];
}
