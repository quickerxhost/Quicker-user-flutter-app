import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/repositories/payment_repository.dart';
import '../domain/models/payment_method_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioClientProvider));
});

final savedCardsProvider = FutureProvider<List<SavedCardModel>>((ref) async {
  final result = await ref.watch(paymentRepositoryProvider).getSavedCards();
  return result.when(success: (v) => v, failure: (_) => const []);
});

/// The currently-selected payment method for checkout — defaults to UPI,
/// the most common choice for hyperlocal delivery in India.
final selectedPaymentMethodProvider = StateProvider<PaymentType>((ref) => PaymentType.upi);
