import 'package:flutter_test/flutter_test.dart';
import 'package:quickerx/core/network/dio_client.dart';
import 'package:quickerx/core/storage/secure_storage_service.dart';
import 'package:quickerx/features/coupons/data/repositories/coupon_repository.dart';

void main() {
  // `ApiEndpoints.applyCoupon` is intentionally blank (no backend yet), so
  // this exercises the fixture-mode validation contract: min-order checks
  // and unknown-code rejection must keep working once the real endpoint
  // replaces the fixture.
  group('CouponRepository.applyCoupon (fixture mode)', () {
    late CouponRepository repository;

    setUp(() {
      repository = CouponRepository(DioClient(SecureStorageService()));
    });

    test('rejects an unknown coupon code', () async {
      final result = await repository.applyCoupon('NOTREAL', orderValue: 500);
      result.when(
        success: (_) => fail('Expected failure for an unknown code'),
        failure: (e) => expect(e.message, contains('Invalid')),
      );
    });

    test('rejects a valid code below its minimum order value', () async {
      final result = await repository.applyCoupon('SAVE20', orderValue: 100);
      result.when(
        success: (_) => fail('Expected failure below minimum order value'),
        failure: (e) => expect(e.message, isNotEmpty),
      );
    });

    test('accepts a valid code at/above its minimum order value', () async {
      final result = await repository.applyCoupon('first50', orderValue: 250);
      result.when(
        success: (coupon) => expect(coupon.code, 'FIRST50'),
        failure: (e) => fail('Expected success, got: ${e.message}'),
      );
    });

    test('percent coupon discount respects the max-discount cap', () async {
      final result = await repository.applyCoupon('SAVE20', orderValue: 1000);
      result.when(
        success: (coupon) => expect(coupon.discountFor(1000), 100), // 20% of 1000 = 200, capped at 100
        failure: (e) => fail('Expected success, got: ${e.message}'),
      );
    });
  });
}
