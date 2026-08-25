import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/repositories/auth_repository.dart';
import '../domain/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioClientProvider), ref.watch(secureStorageProvider));
});

enum AuthStatus { idle, sendingOtp, otpSent, verifying, success, error }

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? errorMessage;
  final UserModel? user;

  const AuthState({this.status = AuthStatus.idle, this.phoneNumber, this.errorMessage, this.user});

  AuthState copyWith({AuthStatus? status, String? phoneNumber, String? errorMessage, UserModel? user}) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(repository: ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({required this.repository}) : super(const AuthState());

  final AuthRepository repository;

  /// Request OTP for the given phone number (E.164 format, e.g., +919876543210)
  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.sendingOtp, errorMessage: null, phoneNumber: phoneNumber);
    final result = await repository.sendOtp(phoneNumber);
    result.when(
      success: (_) => state = state.copyWith(status: AuthStatus.otpSent),
      failure: (e) => state = state.copyWith(status: AuthStatus.error, errorMessage: e.message),
    );
  }

  /// Resend OTP to the same phone number
  Future<void> resendOtp() async {
    if (state.phoneNumber == null) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'No phone number stored. Please re-enter.');
      return;
    }
    await sendOtp(state.phoneNumber!);
  }

  /// Verify the OTP and obtain JWT tokens from backend
  Future<void> verifyOtp(String otp) async {
    final phoneNumber = state.phoneNumber;
    if (phoneNumber == null) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Please request an OTP first.');
      return;
    }
    state = state.copyWith(status: AuthStatus.verifying, errorMessage: null);
    final result = await repository.verifyOtp(phoneNumber, otp);
    result.when(
      success: (user) => state = state.copyWith(status: AuthStatus.success, user: user),
      failure: (e) => state = state.copyWith(status: AuthStatus.error, errorMessage: e.message),
    );
  }

  /// Loads the saved user profile (name, email, phone) from the backend.
  /// Called on app start when a session token exists so the profile screen
  /// and home greeting show the user's stored details without re-login.
  Future<void> loadProfile() async {
    final result = await repository.getMe();
    result.when(
      success: (user) => state = state.copyWith(status: AuthStatus.success, user: user),
      failure: (_) => {/* keep existing state; non-blocking on failure */},
    );
  }

  /// Optional: complete profile after OTP verification
  Future<void> register({required String fullName, String? email, String? language}) async {
    state = state.copyWith(status: AuthStatus.verifying, errorMessage: null);
    final result = await repository.register(fullName: fullName, email: email, language: language);
    result.when(
      success: (user) => state = state.copyWith(status: AuthStatus.success, user: user),
      failure: (e) => state = state.copyWith(status: AuthStatus.error, errorMessage: e.message),
    );
  }

  /// Change password (first login flow)
  Future<void> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(status: AuthStatus.verifying, errorMessage: null);
    final result = await repository.changePassword(currentPassword, newPassword);
    result.when(
      success: (_) => state = state.copyWith(status: AuthStatus.success),
      failure: (e) => state = state.copyWith(status: AuthStatus.error, errorMessage: e.message),
    );
  }

  void reset() => state = const AuthState();
}