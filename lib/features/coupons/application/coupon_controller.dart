import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/repositories/coupon_repository.dart';
import '../domain/models/coupon_model.dart';

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return CouponRepository(ref.watch(dioClientProvider));
});

final availableCouponsProvider = FutureProvider<List<CouponModel>>((ref) async {
  final result = await ref.watch(couponRepositoryProvider).getAvailableCoupons();
  return result.when(success: (v) => v, failure: (_) => const []);
});

/// The single currently-applied coupon, shared between the Cart screen's
/// "Coupon Card" and the Checkout screen's order summary.
final appliedCouponProvider = StateProvider<CouponModel?>((ref) => null);

class CouponApplyController extends StateNotifier<AsyncValue<void>> {
  CouponApplyController(this._ref, this._repository) : super(const AsyncData(null));
  final Ref _ref;
  final CouponRepository _repository;

  Future<bool> apply(String code, {required double orderValue}) async {
    state = const AsyncLoading();
    final result = await _repository.applyCoupon(code, orderValue: orderValue);
    return result.when(
      success: (coupon) {
        _ref.read(appliedCouponProvider.notifier).state = coupon;
        state = const AsyncData(null);
        return true;
      },
      failure: (e) {
        state = AsyncError(e, StackTrace.current);
        return false;
      },
    );
  }

  void remove() {
    _ref.read(appliedCouponProvider.notifier).state = null;
    state = const AsyncData(null);
  }
}

final couponApplyControllerProvider = StateNotifierProvider<CouponApplyController, AsyncValue<void>>((ref) {
  return CouponApplyController(ref, ref.watch(couponRepositoryProvider));
});
