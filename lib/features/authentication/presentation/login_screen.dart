import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_controller.dart';

/// Login screen with mobile number input.
///
/// Flow:
/// 1. Enter 10-digit Indian mobile number
/// 2. Send OTP to Spring Boot backend
/// 3. Backend returns test OTP in local/dev mode
/// 4. Flutter shows OTP popup
/// 5. User presses OK
/// 6. Navigate to OTP verification screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final mobileNumber = _phoneController.text.trim();

    // Backend expects E.164 format.
    final fullNumber = '+91$mobileNumber';

    await ref
        .read(authControllerProvider.notifier)
        .sendOtp(fullNumber);
  }

  // ============================================================
  // TEST OTP POPUP
  // ============================================================

  Future<void> _showTestOtpDialog(String otp) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 26,
              ),
              SizedBox(width: 10),
              Text('Test OTP'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your OTP is:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ==================== CHANGED ====================
              Text(
                otp,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
              // ==================== CHANGED ====================

              const SizedBox(height: 12),

              const Text(
                'This OTP is shown only for local testing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    // ==========================================================
    // AFTER POPUP CLOSE → OPEN OTP SCREEN
    // ==========================================================

    if (!mounted) {
      return;
    }

    final currentState = ref.read(authControllerProvider);

    if (currentState.status == AuthStatus.otpSent) {
      context.push(
        RoutePaths.otpVerification,
        extra: {
          'phoneNumber': fullPhoneNumberFromState(currentState),
        },
      );
    }
  }

  // ============================================================
  // PHONE NUMBER FROM STATE
  // ============================================================

  String fullPhoneNumberFromState(AuthState state) {
    return state.phoneNumber ?? '+91${_phoneController.text.trim()}';
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    final isSendingOtp =
        authState.status == AuthStatus.sendingOtp;

    // ==========================================================
    // AUTH STATE LISTENER
    // ==========================================================

    ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        // ------------------------------------------------------
        // ERROR
        // ------------------------------------------------------

        if (next.status == AuthStatus.error &&
            next.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(next.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
        }

        // ------------------------------------------------------
        // OTP SENT
        // ------------------------------------------------------

        if (previous?.status != AuthStatus.otpSent &&
            next.status == AuthStatus.otpSent) {
          // ==================== CHANGED ====================

          // Local testing OTP received from backend.
          final otp = next.testOtp;

          if (otp != null && otp.isNotEmpty) {
            _showTestOtpDialog(otp);
          } else {
            // If backend does not return test OTP,
            // directly navigate to verification screen.
            context.push(
              RoutePaths.otpVerification,
              extra: {
                'phoneNumber': next.phoneNumber,
              },
            );
          }

          // ==================== CHANGED ====================
        }
      },
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            AppSpacing.marginMobile,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: AppSpacing.xl,
                ),

                // =================================================
                // LOGO
                // =================================================

                const AppLogo(
                  variant: AppLogoVariant.mark,
                  height: 56,
                ),

                const SizedBox(
                  height: AppSpacing.lg,
                ),

                // =================================================
                // TITLE
                // =================================================

                Text(
                  'Welcome Back',
                  style: AppTypography.headlineLgMobile(),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Enter your mobile number to continue',
                  style: AppTypography.bodyMd(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.xl,
                ),

                // =================================================
                // MOBILE NUMBER
                // =================================================

                AppTextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,

                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],

                  hintText: 'Mobile number',

                  validator: Validators.mobileNumber,

                  prefixWidget: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🇮🇳',
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Text(
                          '+91',
                          style: AppTypography.bodyMd(),
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        const Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),

                        Container(
                          margin: const EdgeInsets.only(
                            left: 10,
                          ),
                          width: 1,
                          height: 20,
                          color: AppColors.outlineVariant,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.lg,
                ),

                // =================================================
                // CONTINUE BUTTON
                // =================================================

                PrimaryButton(
                  label: 'Continue',
                  isLoading: isSendingOtp,
                  onPressed: _submit,
                ),

                const SizedBox(
                  height: AppSpacing.xl,
                ),

                // =================================================
                // TERMS & PRIVACY
                // =================================================

                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'By continuing you agree to our ',
                        style: AppTypography.labelLg(
                          color: AppColors.outline,
                        ).copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      Text(
                        'Terms & Conditions',
                        style: AppTypography.labelLg(
                          color: AppColors.primary,
                        ),
                      ),

                      Text(
                        ' and ',
                        style: AppTypography.labelLg(
                          color: AppColors.outline,
                        ).copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      Text(
                        'Privacy Policy',
                        style: AppTypography.labelLg(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}