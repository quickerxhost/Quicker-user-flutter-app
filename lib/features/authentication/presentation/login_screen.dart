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
/// Enter 10-digit Indian mobile number → OTP sent via backend → verify on next screen.
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final fullNumber = '+91${_phoneController.text.trim()}';
    await ref.read(authControllerProvider.notifier).sendOtp(fullNumber);
    final state = ref.read(authControllerProvider);
    if (state.status == AuthStatus.otpSent && mounted) {
      context.push(
        RoutePaths.otpVerification,
        extra: {'phoneNumber': fullNumber},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isSendingOtp = authState.status == AuthStatus.sendingOtp;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                const AppLogo(variant: AppLogoVariant.mark, height: 56),
                const SizedBox(height: AppSpacing.lg),
                Text('Welcome Back', style: AppTypography.headlineLgMobile()),
                const SizedBox(height: 4),
                Text('Enter your mobile number to continue', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  hintText: 'Mobile number',
                  validator: Validators.mobileNumber,
                  prefixWidget: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text('+91', style: AppTypography.bodyMd()),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.onSurfaceVariant),
                        Container(margin: const EdgeInsets.only(left: 10), width: 1, height: 20, color: AppColors.outlineVariant),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(label: 'Continue', isLoading: isSendingOtp, onPressed: _submit),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text('By continuing you agree to our ', style: AppTypography.labelLg(color: AppColors.outline).copyWith(fontWeight: FontWeight.w400)),
                      Text('Terms & Conditions', style: AppTypography.labelLg(color: AppColors.primary)),
                      Text(' and ', style: AppTypography.labelLg(color: AppColors.outline).copyWith(fontWeight: FontWeight.w400)),
                      Text('Privacy Policy', style: AppTypography.labelLg(color: AppColors.primary)),
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