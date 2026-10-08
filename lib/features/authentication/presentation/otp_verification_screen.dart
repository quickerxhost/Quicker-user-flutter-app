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

/// OTP verification screen:
/// - 6-digit boxed input
/// - resend countdown
/// - local/dev test OTP notification
/// - backend handles OTP verification directly
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  static const int _otpLength = 6;

  final List<TextEditingController> _controllers =
      List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes =
      List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  Timer? _timer;
  Timer? _otpBannerTimer;

  int _secondsLeft = 30;

  String? _visibleOtp;
  bool _isOtpBannerVisible = false;

  @override
  void initState() {
    super.initState();

    _startTimer();

    // OTP request Login Screen वर झालेला आहे.
    // त्यामुळे OTP screen उघडल्यानंतर current state मधून
    // test OTP घेऊन notification दाखवतो.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final authState = ref.read(authControllerProvider);

      if (authState.status == AuthStatus.otpSent &&
          authState.testOtp != null &&
          authState.testOtp!.isNotEmpty) {
        _displayOtpBanner(authState.testOtp!);
      }
    });
  }

  // ==========================================================
  // TIMER
  // ==========================================================

  void _startTimer() {
    _timer?.cancel();

    _secondsLeft = 30;

    if (mounted) {
      setState(() {});
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_secondsLeft <= 0) {
          timer.cancel();
          return;
        }

        setState(() {
          _secondsLeft--;
        });
      },
    );
  }

  // ==========================================================
  // SHOW OTP BANNER
  // ==========================================================

  void _displayOtpBanner(String otp) {
    _otpBannerTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _visibleOtp = otp;
      _isOtpBannerVisible = true;
    });

    // Notification 4 seconds नंतर automatically disappear होईल.
    _otpBannerTimer = Timer(
      const Duration(seconds: 4),
      () {
        if (!mounted) return;

        setState(() {
          _isOtpBannerVisible = false;
        });
      },
    );
  }

  // ==========================================================
  // HIDE OTP BANNER
  // ==========================================================

  void _hideOtpBanner() {
    _otpBannerTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _isOtpBannerVisible = false;
    });
  }

  // ==========================================================
  // OTP CODE
  // ==========================================================

  String get _code {
    return _controllers
        .map((controller) => controller.text)
        .join();
  }

  // ==========================================================
  // CLEAR OTP
  // ==========================================================

  void _clearOtpFields() {
    for (final controller in _controllers) {
      controller.clear();
    }

    if (mounted) {
      setState(() {});
    }

    _focusNodes.first.requestFocus();
  }

  // ==========================================================
  // VERIFY OTP
  // ==========================================================

  Future<void> _verify() async {
    if (_code.length != _otpLength) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(_code);

    if (!mounted) return;

    final state = ref.read(authControllerProvider);

    if (state.status == AuthStatus.success) {
      final user = state.user;

      final hasProfile =
          user?.fullName?.trim().isNotEmpty == true;

      context.go(
        hasProfile
            ? RoutePaths.home
            : RoutePaths.registration,
      );
    }
  }

  // ==========================================================
  // RESEND OTP
  // ==========================================================

  Future<void> _resendOtp() async {
    _hideOtpBanner();

    _clearOtpFields();

    _startTimer();

    await ref
        .read(authControllerProvider.notifier)
        .resendOtp();
  }

  // ==========================================================
  // OTP BOX CHANGE
  // ==========================================================

  void _handleOtpChanged(
    int index,
    String value,
  ) {
    if (value.isNotEmpty &&
        index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (mounted) {
      setState(() {});
    }

    // सर्व 6 digits भरले की automatically verify.
    if (_code.length == _otpLength) {
      _verify();
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _timer?.cancel();
    _otpBannerTimer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(
      authControllerProvider,
    );

    final isVerifying =
        authState.status == AuthStatus.verifying;

    final isSendingOtp =
        authState.status == AuthStatus.sendingOtp;

    // Backend state changes listen करतो.
    ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        // -----------------------------------------------
        // NEW OTP RECEIVED
        // -----------------------------------------------

        if (next.status == AuthStatus.otpSent &&
            next.testOtp != null &&
            next.testOtp!.isNotEmpty) {
          _displayOtpBanner(next.testOtp!);
          return;
        }

        // -----------------------------------------------
        // OTP VERIFICATION ERROR
        // -----------------------------------------------

        if (next.status == AuthStatus.error &&
            next.errorMessage != null) {
          _clearOtpFields();

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  next.errorMessage!,
                ),
                backgroundColor:
                    AppColors.error,
              ),
            );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(),

      body: Stack(
        children: [
          // =================================================
          // MAIN OTP SCREEN
          // =================================================

          Padding(
            padding: const EdgeInsets.all(
              AppSpacing.marginMobile,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify Your Number',
                  style:
                      AppTypography.headlineLgMobile(),
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter the 6-digit code sent to ${widget.phoneNumber}',
                  style: AppTypography.bodyMd(
                    color:
                        AppColors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.xl,
                ),

                // =================================================
                // OTP BOXES
                // =================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _otpLength,
                    (index) {
                      return _OtpBox(
                        controller:
                            _controllers[index],
                        focusNode:
                            _focusNodes[index],
                        autofocus: index == 0,
                        onChanged: (value) {
                          _handleOtpChanged(
                            index,
                            value,
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.xl,
                ),

                // =================================================
                // RESEND
                // =================================================

                Center(
                  child: _secondsLeft > 0
                      ? Text(
                          'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                          style:
                              AppTypography.bodyMd(
                            color: AppColors
                                .onSurfaceVariant,
                          ),
                        )
                      : TextButton(
                          onPressed:
                              isSendingOtp
                                  ? null
                                  : _resendOtp,
                          child: isSendingOtp
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Resend OTP',
                                ),
                        ),
                ),

                const Spacer(),

                // =================================================
                // VERIFY BUTTON
                // =================================================

                PrimaryButton(
                  label: 'Verify',
                  trailingIcon: null,
                  isLoading: isVerifying,
                  onPressed:
                      _code.length ==
                              _otpLength
                          ? _verify
                          : null,
                ),
              ],
            ),
          ),

          // =====================================================
          // TEST OTP NOTIFICATION
          // =====================================================

          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: IgnorePointer(
              ignoring: !_isOtpBannerVisible,
              child: AnimatedSlide(
                duration:
                    const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                offset: _isOtpBannerVisible
                    ? Offset.zero
                    : const Offset(0, -1.5),
                child: AnimatedOpacity(
                  duration:
                      const Duration(milliseconds: 250),
                  opacity:
                      _isOtpBannerVisible
                          ? 1.0
                          : 0.0,
                  child: _TestOtpNotification(
                    otp: _visibleOtp ?? '',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TEST OTP NOTIFICATION
// =============================================================

class _TestOtpNotification
    extends StatelessWidget {
  const _TestOtpNotification({
    required this.otp,
  });

  final String otp;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius:
          BorderRadius.circular(16),
      color: Theme.of(context)
          .colorScheme
          .surface,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(
              alpha: 0.20,
            ),
          ),
        ),
        child: Row(
          children: [
            // ---------------------------------------------
            // ICON
            // ---------------------------------------------

            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    AppColors.primary.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons
                    .notifications_active_outlined,
                color: AppColors.primary,
                size: 23,
              ),
            ),

            const SizedBox(width: 12),

            // ---------------------------------------------
            // TEXT
            // ---------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quicker-X',
                    style:
                        AppTypography.bodyMd(
                      color:
                          AppColors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Your verification OTP is',
                    style:
                        AppTypography.bodyMd(
                      color: AppColors
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ---------------------------------------------
            // OTP
            // ---------------------------------------------

            Text(
              otp,
              style:
                  AppTypography.titleLg(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// OTP BOX
// =============================================================

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
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: AppTypography.titleLg().copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          counterText: '',
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}