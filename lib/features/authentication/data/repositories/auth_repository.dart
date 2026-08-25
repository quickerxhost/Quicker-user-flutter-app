import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/models/user_model.dart';

/// AuthRepository using the backend's own OTP system (no Firebase).
/// 
/// Flow:
/// 1. sendOtp(phoneNumber) → POST /auth/otp/request
/// 2. verifyOtp(otp, phoneNumber) → POST /auth/otp/verify → returns access/refresh tokens + user
/// 3. Tokens are stored in SecureStorage, DioClient injects them automatically
class AuthRepository {
  AuthRepository(this._client, this._secureStorage);
  final DioClient _client;
  final SecureStorageService _secureStorage;

  /// Request an OTP to be sent to the given phone number.
  Future<ApiResult<void>> sendOtp(String phoneNumber) async {
    try {
      await _client.guard((dio) async {
        await dio.post(
          ApiEndpoints.sendOtp,
          data: {'mobileNumber': phoneNumber},
        );
      });
      return const ApiResult.success(null);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  /// Verify the OTP and exchange for JWT tokens.
  /// On success, tokens are saved to SecureStorage and DioClient will use them.
  Future<ApiResult<UserModel>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.post(
          ApiEndpoints.verifyOtp,
          data: {'mobileNumber': phoneNumber, 'otp': otp},
        );
        return response.data as Map<String, dynamic>;
      });

      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken != null) await _secureStorage.saveAccessToken(accessToken);
      if (refreshToken != null) await _secureStorage.saveRefreshToken(refreshToken);

      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      return ApiResult.success(user);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  /// Resend OTP (same as sendOtp)
  Future<ApiResult<void>> resendOtp(String phoneNumber) => sendOtp(phoneNumber);

  /// Register/complete profile after OTP verification (optional, for profile completion)
  Future<ApiResult<UserModel>> register({
    required String fullName,
    String? email,
    String? language,
  }) async {
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.post(
          ApiEndpoints.register,
          data: {'fullName': fullName, 'email': email, 'language': language},
        );
        return response.data as Map<String, dynamic>;
      });
      return ApiResult.success(UserModel.fromJson(data));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  /// Get current user profile
  Future<ApiResult<UserModel>> getMe() async {
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(ApiEndpoints.me);
        return response.data as Map<String, dynamic>;
      });
      return ApiResult.success(UserModel.fromJson(data['user'] as Map<String, dynamic>));
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  /// Change password (first login flow)
  Future<ApiResult<void>> changePassword(String currentPassword, String newPassword) async {
    try {
      await _client.guard((dio) async {
        await dio.post(
          ApiEndpoints.changePassword,
          data: {'currentPassword': currentPassword, 'newPassword': newPassword},
        );
      });
      return const ApiResult.success(null);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  /// Logout - clear tokens
  Future<void> logout() => _secureStorage.clearSession();
}