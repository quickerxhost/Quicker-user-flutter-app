import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../domain/models/payment_method_model.dart';

/// `ApiEndpoints.paymentMethods` is currently BLANK — falls back to a
/// small fixture of saved cards. Card entry itself is UI-only for now: no
/// PCI-scope tokenization vendor was specified in the tech stack, so a real
/// "Add Card" call should go through whatever payment gateway SDK you pick
/// (Razorpay/Stripe/etc.) rather than your own backend directly.
class PaymentRepository {
  PaymentRepository(this._client);
  final DioClient _client;

  Future<ApiResult<List<SavedCardModel>>> getSavedCards() async {
    if (ApiEndpoints.paymentMethods.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      return const ApiResult.success([
        SavedCardModel(id: 'card-1', last4: '4242', network: 'Visa', expiry: '11/27'),
      ]);
    }
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.paymentMethods);
        return (response.data as List).cast<Map<String, dynamic>>();
      });
      return ApiResult.success(data.map(SavedCardModel.fromJson).toList());
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }
}
