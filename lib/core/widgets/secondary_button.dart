import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.leadingWidget,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;

  /// Use for custom leading content (e.g. a Google "G" logo) instead of an
  /// [IconData].
  final Widget? leadingWidget;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outlineVariant, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingWidget != null) leadingWidget!,
                  if (leadingIcon != null)
                    Icon(leadingIcon, size: 20, color: AppColors.onSurface),
                  if (leadingWidget != null || leadingIcon != null)
                    const SizedBox(width: 10),
                  Text(label, style: AppTypography.labelLg(color: AppColors.onSurface)),
                ],
              ),
      ),
    );
  }
}
