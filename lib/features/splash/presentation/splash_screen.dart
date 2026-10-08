import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_logo.dart';
import '../application/splash_controller.dart';

/// Matches Stitch `splash_screen`: centered logo + "QuickerX" wordmark +
/// tagline, bottom progress bar with "Initializing" status. The animated
/// WebGL shader background in the HTML source is approximated here with a
/// soft radial [RadialGradient] (see [_SplashBackground]) since Flutter
/// doesn't need a canvas shader for an equivalent visual effect.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeScale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(splashDestinationProvider, (previous, next) {
      next.whenData((route) {
        if (mounted) context.go(route);
      });
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
          const Positioned.fill(child: _SplashBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20),
              child: Column(
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _fadeScale,
                    child: FadeTransition(
                      opacity: _fadeScale,
                      child: const AppLogo(variant: AppLogoVariant.full, height: 260),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation(AppColors.primaryContainer),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'INITIALIZING',
                              style: AppTypography.labelLg(color: AppColors.outline).copyWith(
                                letterSpacing: 2,
                                color: AppColors.outline.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.surface,
          ],
        ),
      ),
    );
  }
}
