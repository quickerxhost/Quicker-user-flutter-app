import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_success_dialog.dart';
import '../../../core/widgets/coupon_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/application/cart_controller.dart';
import '../application/coupon_controller.dart';
import '../domain/models/coupon_model.dart';

/// No Stitch design exists for this screen — built to match the app's
/// token system per the PRD's Coupon spec: recommended / platform / shop /
/// restaurant sections, copy code, apply/remove, success animation.
class CouponScreen extends ConsumerStatefulWidget {
  const CouponScreen({super.key});

  @override
  ConsumerState<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends ConsumerState<CouponScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _apply(String code) async {
    final orderValue = ref.read(cartPriceSummaryProvider).subtotal;
    final ok = await ref.read(couponApplyControllerProvider.notifier).apply(code, orderValue: orderValue);
    if (!mounted) return;
    if (ok) {
      await AnimatedSuccessDialog.show(context, title: 'Coupon Applied!', message: '$code has been applied to your order.');
      if (mounted) context.pop();
    } else {
      final error = ref.read(couponApplyControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error?.toString() ?? 'Could not apply coupon.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(availableCouponsProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final applyState = ref.watch(couponApplyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apply Coupon')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'Enter coupon code'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: applyState.isLoading || _codeController.text.trim().isEmpty
                      ? null
                      : () => _apply(_codeController.text.trim()),
                  child: applyState.isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Apply'),
                ),
              ],
            ),
          ),
          Expanded(
            child: couponsAsync.when(
              loading: () => const LoadingView(),
              error: (error, _) => AppErrorView(message: error.toString(), onRetry: () => ref.invalidate(availableCouponsProvider)),
              data: (coupons) {
                if (coupons.isEmpty) {
                  return const EmptyView(icon: Icons.local_offer_outlined, title: 'No coupons available', message: 'Check back soon for new offers!');
                }
                final recommended = coupons.where((c) => c.isRecommended).toList();
                final platform = coupons.where((c) => c.scope == CouponScope.platform && !c.isRecommended).toList();
                final shop = coupons.where((c) => c.scope == CouponScope.shop).toList();
                final restaurant = coupons.where((c) => c.scope == CouponScope.restaurant).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, 0, AppSpacing.marginMobile, AppSpacing.xl),
                  children: [
                    if (recommended.isNotEmpty) _Section(title: 'Recommended for You', coupons: recommended, applied: appliedCoupon, onApply: _apply),
                    if (platform.isNotEmpty) _Section(title: 'Platform Coupons', coupons: platform, applied: appliedCoupon, onApply: _apply),
                    if (shop.isNotEmpty) _Section(title: 'Shop Coupons', coupons: shop, applied: appliedCoupon, onApply: _apply),
                    if (restaurant.isNotEmpty) _Section(title: 'Restaurant Coupons', coupons: restaurant, applied: appliedCoupon, onApply: _apply),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({required this.title, required this.coupons, required this.applied, required this.onApply});
  final String title;
  final List<CouponModel> coupons;
  final CouponModel? applied;
  final Future<void> Function(String) onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(title, style: AppTypography.titleLg().copyWith(fontSize: 16)),
        ),
        ...coupons.map((coupon) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: CouponCard(
                coupon: coupon,
                applied: applied?.code == coupon.code,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: coupon.code));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${coupon.code} copied')));
                },
                onApply: () => onApply(coupon.code),
                onRemove: () => ref.read(couponApplyControllerProvider.notifier).remove(),
              ),
            )),
      ],
    );
  }
}
