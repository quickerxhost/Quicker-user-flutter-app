import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../authentication/application/auth_controller.dart';

/// Profile screen using backend auth state (UserModel from JWT).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryFixed,
              child: Text(
                (user?.fullName?.isNotEmpty == true ? user!.fullName![0] : 'Q').toUpperCase(),
                style: AppTypography.headlineLgMobile(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(user?.fullName ?? 'Guest User', style: AppTypography.titleLg()),
            const SizedBox(height: 4),
            Text(
              user?.phoneNumber ?? user?.email ?? 'Not signed in',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            _MenuTile(icon: Icons.favorite_border_rounded, label: 'My Wishlist', onTap: () => context.push(RoutePaths.wishlist)),
            _MenuTile(icon: Icons.bookmark_border_rounded, label: 'Saved for Later', onTap: () => context.push(RoutePaths.saveForLater)),
            _MenuTile(icon: Icons.location_on_outlined, label: 'Delivery Addresses', onTap: () => context.push(RoutePaths.addressList)),
            _MenuTile(icon: Icons.payment_outlined, label: 'Payment Methods', onTap: () => context.push(RoutePaths.paymentMethod)),
            _MenuTile(icon: Icons.restaurant_menu_outlined, label: 'Food Orders', onTap: () => context.push(RoutePaths.restaurantOrders)),
            const Spacer(),
OutlinedButton.icon(
              onPressed: () {
                ref.read(authControllerProvider.notifier).reset();
                ref.read(secureStorageProvider).clearAll();
                if (context.mounted) context.go(RoutePaths.login);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
      onTap: onTap,
    );
  }
}