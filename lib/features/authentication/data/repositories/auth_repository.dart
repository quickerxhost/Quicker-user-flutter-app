import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/models/user_model.dart';

/// AuthRepository using the backend's own OTP system (no Firebase).
///
/// Flow:
/// 1. sendOtp(phoneNumber)
///    → POST /auth/otp/request
///    → returns optional test OTP
///
/// 2. verifyOtp(otp, phoneNumber)
///    → POST /auth/otp/verify
///    → returns access/refresh tokens + user
///
/// 3. Tokens are stored in SecureStorage.
///    DioClient injects them automatically.
class AuthRepository {
  AuthRepository(this._client, this._secureStorage);

  final DioClient _client;
  final SecureStorageService _secureStorage;

  // ============================================================
  // SEND OTP
  // ============================================================

  /// Request an OTP to be sent to the given phone number.
  ///
  /// In local/dev testing mode, the backend returns the generated
  /// OTP in the response.
  ///
  /// Production:
  /// OTP should be sent through SMS provider and should NOT be
  /// returned in the API response.
  Future<ApiResult<String?>> sendOtp(String phoneNumber) async {
    try {
      final response = await _client.guard((dio) async {
        return await dio.post(
          ApiEndpoints.sendOtp,
          data: {
            'mobileNumber': phoneNumber,
          },
        );
      });

      final data = response.data as Map<String, dynamic>;

      // ==================== CHANGED ====================
      // Backend test response:
      // {
      //   "message": "OTP sent successfully",
      //   "otp": "123456"
      // }
      final otp = data['otp'] as String?;
      // ==================== CHANGED ====================

      return ApiResult.success(otp);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  /// Verify the OTP and exchange for JWT tokens.
  ///
  /// On successful verification:
  /// - access token is saved
  /// - refresh token is saved
  /// - user information is returned
  Future<ApiResult<UserModel>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.post(
          ApiEndpoints.verifyOtp,
          data: {
            'mobileNumber': phoneNumber,
            'otp': otp,
          },
        );

        return response.data as Map<String, dynamic>;
      });

      // ========================================================
      // SAVE ACCESS TOKEN
      // ========================================================

      final accessToken = data['accessToken'] as String?;

      if (accessToken != null && accessToken.isNotEmpty) {
        await _secureStorage.saveAccessToken(accessToken);
      }

      // ========================================================
      // SAVE REFRESH TOKEN
      // ========================================================

      final refreshToken = data['refreshToken'] as String?;

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secureStorage.saveRefreshToken(refreshToken);
      }

      // ========================================================
      // USER
      // ========================================================

      final userData = data['user'] as Map<String, dynamic>;

      final user = UserModel.fromJson(userData);

      return ApiResult.success(user);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  /// Resend OTP.
  ///
  /// Same backend endpoint as sendOtp().
  ///
  /// ==================== CHANGED ====================
  /// Return type changed from ApiResult<void> to
  /// ApiResult<String?> because sendOtp() returns the
  /// test OTP in local/dev mode.
  Future<ApiResult<String?>> resendOtp(String phoneNumber) {
    return sendOtp(phoneNumber);
  }

  // ============================================================
  // REGISTER / COMPLETE PROFILE
  // ============================================================

  /// Register/complete profile after OTP verification.
  ///
  /// This is used for profile completion.
  Future<ApiResult<UserModel>> register({
    required String fullName,
    String? email,
    String? language,
  }) async {
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.post(
          ApiEndpoints.register,
          data: {
            'fullName': fullName,
            'email': email,
            'language': language,
          },
        );

        return response.data as Map<String, dynamic>;
      });

      return ApiResult.success(
        UserModel.fromJson(data),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  // ============================================================
  // GET CURRENT USER
  // ============================================================

  /// Get current authenticated user profile.
  Future<ApiResult<UserModel>> getMe() async {
    try {
      final data = await _client.guard((dio) async {
        final response = await dio.get(
          ApiEndpoints.me,
        );

        return response.data as Map<String, dynamic>;
      });

      return ApiResult.success(
        UserModel.fromJson(
          data['user'] as Map<String, dynamic>,
        ),
      );
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  /// Change password for the current authenticated user.
  Future<ApiResult<void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _client.guard((dio) async {
        await dio.post(
          ApiEndpoints.changePassword,
          data: {
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          },
        );
      });

      return const ApiResult.success(null);
    } on NetworkException catch (e) {
      return ApiResult.failure(e);
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  /// Logout.
  ///
  /// Clears locally stored access and refresh tokens.
  Future<void> logout() {
    return _secureStorage.clearSession();
  }
}