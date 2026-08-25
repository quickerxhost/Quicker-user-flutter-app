import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Scale+fade animated checkmark dialog — used for "Coupon Applied!" and
/// other short-lived success confirmations (the Order Success screen uses
/// its own full-screen version for a bigger moment).
class AnimatedSuccessDialog extends StatefulWidget {
  const AnimatedSuccessDialog({super.key, required this.title, this.message});
  final String title;
  final String? message;

  static Future<void> show(BuildContext context, {required String title, String? message}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AnimatedSuccessDialog(title: title, message: message),
    );
  }

  @override
  State<AnimatedSuccessDialog> createState() => _AnimatedSuccessDialogState();
}

class _AnimatedSuccessDialogState extends State<AnimatedSuccessDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(widget.title, style: AppTypography.titleLg(), textAlign: TextAlign.center),
              if (widget.message != null) ...[
                const SizedBox(height: 4),
                Text(widget.message!, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
