import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'primary_button.dart';

/// Centered spinner for full-screen loading states.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// Generic full-screen error state with a retry action. [icon]/[title]
/// default to a generic API-error look; pass a different icon+title for
/// no-internet / GPS-disabled / permission-denied variants.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'Please check your connection and try again.',
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.titleLg(), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: retryLabel, onPressed: onRetry, trailingIcon: null),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty-state placeholder (e.g. no search results, empty wishlist).
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.outline),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.titleLg(), textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
