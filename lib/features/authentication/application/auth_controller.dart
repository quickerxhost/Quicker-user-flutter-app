import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/repositories/auth_repository.dart';
import '../domain/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(secureStorageProvider),
  );
});

enum AuthStatus {
  idle,
  sendingOtp,
  otpSent,
  verifying,
  success,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? errorMessage;
  final UserModel? user;

  // ==================== CHANGED ====================
  // Backend local testing OTP
  final String? testOtp;
  // ==================== CHANGED ====================

  const AuthState({
    this.status = AuthStatus.idle,
    this.phoneNumber,
    this.errorMessage,
    this.user,
    this.testOtp,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? errorMessage,
    UserModel? user,
    String? testOtp,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: errorMessage,
      user: user ?? this.user,
      testOtp: testOtp ?? this.testOtp,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required this.repository,
  }) : super(const AuthState());

  final AuthRepository repository;

  // ============================================================
  // SEND OTP
  // ============================================================

  /// Request OTP for the given phone number.
  ///
  /// Example:
  /// +919876543210
  ///
  /// Local testing:
  /// Backend returns the generated OTP and it is stored in
  /// state.testOtp.
  Future<void> sendOtp(String phoneNumber) async {
    // ==================== CHANGED ====================
    state = state.copyWith(
      status: AuthStatus.sendingOtp,
      errorMessage: null,
      phoneNumber: phoneNumber,
      testOtp: null,
    );
    // ==================== CHANGED ====================

    final result = await repository.sendOtp(phoneNumber);

    result.when(
      success: (otp) {
        // ==================== CHANGED ====================
        // Save OTP returned by backend.
        state = state.copyWith(
          status: AuthStatus.otpSent,
          testOtp: otp,
          errorMessage: null,
        );
        // ==================== CHANGED ====================
      },
      failure: (e) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.message,
        );
      },
    );
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  /// Resend OTP to the same phone number.
  Future<void> resendOtp() async {
    final phoneNumber = state.phoneNumber;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage:
            'No phone number stored. Please re-enter your phone number.',
      );
      return;
    }

    // ==================== CHANGED ====================
    // sendOtp() will request a new OTP and save it in testOtp.
    await sendOtp(phoneNumber);
    // ==================== CHANGED ====================
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  /// Verify the OTP and obtain JWT tokens from backend.
  Future<void> verifyOtp(String otp) async {
    final phoneNumber = state.phoneNumber;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Please request an OTP first.',
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.verifying,
      errorMessage: null,
    );

    final result = await repository.verifyOtp(
      phoneNumber,
      otp,
    );

    result.when(
      success: (user) {
        state = state.copyWith(
          status: AuthStatus.success,
          user: user,
          errorMessage: null,
        );
      },
      failure: (e) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.message,
        );
      },
    );
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  /// Loads the saved user profile from backend.
  ///
  /// Called on app start when a session token exists.
  Future<void> loadProfile() async {
    final result = await repository.getMe();

    result.when(
      success: (user) {
        state = state.copyWith(
          status: AuthStatus.success,
          user: user,
        );
      },
      failure: (_) {
        // Keep existing state.
        // Profile loading is non-blocking.
      },
    );
  }

  // ============================================================
  // REGISTER / COMPLETE PROFILE
  // ============================================================

  /// Complete profile after OTP verification.
  Future<void> register({
    required String fullName,
    String? email,
    String? language,
  }) async {
    state = state.copyWith(
      status: AuthStatus.verifying,
      errorMessage: null,
    );

    final result = await repository.register(
      fullName: fullName,
      email: email,
      language: language,
    );

    result.when(
      success: (user) {
        state = state.copyWith(
          status: AuthStatus.success,
          user: user,
          errorMessage: null,
        );
      },
      failure: (e) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.message,
        );
      },
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  /// Change password during first-login flow.
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = state.copyWith(
      status: AuthStatus.verifying,
      errorMessage: null,
    );

    final result = await repository.changePassword(
      currentPassword,
      newPassword,
    );

    result.when(
      success: (_) {
        state = state.copyWith(
          status: AuthStatus.success,
          errorMessage: null,
        );
      },
      failure: (e) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.message,
        );
      },
    );
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    state = const AuthState();
  }
}