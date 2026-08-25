import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';

/// No Stitch design exists for this screen — built to match the app's
/// design system per the PRD's "Notification Permission" spec (explain
/// benefits, request permission, Continue/Skip).
class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  Future<void> _requestAndContinue(BuildContext context) async {
    await Permission.notification.request();
    if (context.mounted) context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 60),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Stay in the loop', style: AppTypography.headlineLgMobile(), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Get notified about order updates, delivery ETAs, and exclusive offers near you.',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              const _BenefitTile(icon: Icons.local_shipping_outlined, label: 'Live order & delivery tracking'),
              const SizedBox(height: AppSpacing.sm),
              const _BenefitTile(icon: Icons.percent_rounded, label: 'Flash sales & personalized offers'),
              const Spacer(),
              PrimaryButton(
                label: 'Enable Notifications',
                trailingIcon: null,
                onPressed: () => _requestAndContinue(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go(RoutePaths.home),
                child: Text('Skip for now', style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.base)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTypography.bodyMd())),
        ],
      ),
    );
  }
}
