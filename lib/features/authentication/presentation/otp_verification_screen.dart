import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../application/auth_controller.dart';

/// OTP verification screen: 6-digit boxed input with resend countdown.
/// Backend handles OTP verification directly (no verificationId needed).
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.phoneNumber});
  final String phoneNumber;

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const _otpLength = 6;
  final List<TextEditingController> _controllers = List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != _otpLength) return;
    await ref.read(authControllerProvider.notifier).verifyOtp(_code);
    final state = ref.read(authControllerProvider);
    if (state.status == AuthStatus.success && mounted) {
      final user = state.user;
      final hasProfile = user?.fullName?.trim().isNotEmpty == true;
      context.go(hasProfile ? RoutePaths.home : RoutePaths.registration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isVerifying = authState.status == AuthStatus.verifying;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes.first.requestFocus();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error));
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verify Your Number', style: AppTypography.headlineLgMobile()),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_otpLength, (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    autofocus: i == 0,
                    onChanged: (value) {
                      if (value.isNotEmpty && i < _otpLength - 1) {
                        _focusNodes[i + 1].requestFocus();
                      }
                      if (value.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                      if (_code.length == _otpLength) _verify();
                      setState(() {});
                    },
                  )),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: _secondsLeft > 0
                  ? Text('Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                      style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant))
                  : TextButton(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).resendOtp();
                        _startTimer();
                      },
                      child: const Text('Resend OTP'),
                    ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Verify',
              trailingIcon: null,
              isLoading: isVerifying,
              onPressed: _code.length == _otpLength ? _verify : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTypography.titleLg(),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.base), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}