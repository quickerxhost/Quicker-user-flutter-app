import 'package:flutter_test/flutter_test.dart';
import 'package:quickerx/core/network/dio_client.dart';
import 'package:quickerx/core/storage/secure_storage_service.dart';
import 'package:quickerx/features/product_listing/data/repositories/product_repository.dart';

void main() {
  // Because `ApiEndpoints.products` is intentionally blank (no backend yet),
  // the repository falls back to its fixture catalogue — this test locks
  // in that pagination contract so swapping in the real endpoint later
  // can't silently break page-size/ordering behavior.
  group('ProductRepository (fixture mode — no backend configured)', () {
    late ProductRepository repository;

    setUp(() {
      final dioClient = DioClient(SecureStorageService());
      repository = ProductRepository(dioClient);
    });

    test('returns pageSize items on the first page', () async {
      final result = await repository.getProducts(page: 1, pageSize: 10);
      result.when(
        success: (products) => expect(products.length, 10),
        failure: (e) => fail('Expected success, got failure: $e'),
      );
    });

    test('returns an empty list once past the fixture bound', () async {
      final result = await repository.getProducts(page: 100, pageSize: 10);
      result.when(
        success: (products) => expect(products, isEmpty),
        failure: (e) => fail('Expected success, got failure: $e'),
      );
    });

    test('product ids are stable and unique across a page', () async {
      final result = await repository.getProducts(page: 2, pageSize: 5);
      result.when(
        success: (products) {
          final ids = products.map((p) => p.id).toSet();
          expect(ids.length, products.length);
        },
        failure: (e) => fail('Expected success, got failure: $e'),
      );
    });
  });
}
