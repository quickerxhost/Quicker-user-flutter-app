import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/price_summary_card.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/state_views.dart';
import '../../coupons/application/coupon_controller.dart';
import '../../coupons/domain/models/coupon_model.dart';
import '../application/cart_controller.dart';
import '../domain/models/cart_item_model.dart';

/// Professional cart screen inspired by leading online grocery apps
/// (Blinkit / BigBasket / Amazon): a branded header with a hanging cart
/// logo and live item badge, free-delivery progress, items grouped by shop,
/// coupon card, bill summary and a sticky gradient checkout bar.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static const _freeDeliveryThreshold = 499.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartControllerProvider);
    final appliedCoupon = ref.watch(appliedCouponProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: cartAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => AppErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(cartControllerProvider)),
          data: (items) {
            final totalQuantity =
                items.fold<int>(0, (sum, item) => sum + item.quantity);

            if (items.isEmpty) {
              return const Column(
                children: [
                  _CartHeader(totalQuantity: 0),
                  Expanded(child: _EmptyCart()),
                ],
              );
            }

            // Compute groups and summary directly from data to avoid timing issues
            final groups = _computeGroupsInline(items);
            final summary = _computeSummaryInline(items);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _CartHeader(totalQuantity: totalQuantity)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: groups.length +
                        4, // free delivery + groups + coupon + price summary
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                    (context, index) {
                      if (index == 0) {
                        return _StaggerItem(
                          index: 0,
                          child: _FreeDeliveryBar(
                              subtotal: summary.subtotal,
                              threshold: _freeDeliveryThreshold),
                        );
                      }
                      final groupIndex = index - 1;
                      if (groupIndex < groups.length) {
                        return _StaggerItem(
                          index: groupIndex + 1,
                          child: _ShopGroupCard(group: groups[groupIndex]),
                        );
                      }
                      if (groupIndex == groups.length) {
                        return _StaggerItem(
                          index: groups.length + 1,
                          child: _CouponSummaryCard(
                              appliedCoupon: appliedCoupon,
                              orderValue: summary.subtotal),
                        );
                      }
                      if (groupIndex == groups.length + 1) {
                        return _StaggerItem(
                          index: groups.length + 2,
                          child: PriceSummaryCard(
                              summary: summary, appliedCoupon: appliedCoupon),
                        );
                      }
                      // Last item - bottom padding
                      return const SizedBox(height: 160);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: cartAsync.maybeWhen(
        data: (items) => items.isEmpty
            ? null
            : _StickyCheckoutBar(
                items: items,
                appliedCoupon: appliedCoupon,
                totalQuantity:
                    items.fold<int>(0, (sum, item) => sum + item.quantity)),
        orElse: () => null,
      ),
    );
  }

  /// Compute shop groups directly from cart items (inline to avoid timing issues with controller getters)
  static List<CartShopGroup> _computeGroupsInline(List<CartItemModel> items) {
    final byShop = <String, List<CartItemModel>>{};
    for (final item in items) {
      byShop.putIfAbsent(item.shopId, () => []).add(item);
    }
    return byShop.entries
        .map((e) => CartShopGroup(
            shopId: e.key,
            shopName: e.value.first.shopName,
            etaMinutes: 18,
            items: e.value))
        .toList();
  }

  /// Compute price summary directly from cart items (inline to avoid timing issues with controller getters)
  static CartPriceSummary _computeSummaryInline(List<CartItemModel> items) {
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final mrpTotal = items.fold<double>(0, (sum, i) => sum + i.lineMrpTotal);
    return CartPriceSummary(
      subtotal: subtotal,
      discount: (mrpTotal - subtotal).clamp(0, double.infinity),
      platformFee: items.isEmpty ? 0 : 9,
      deliveryCharge: items.isEmpty ? 0 : 25,
    );
  }
}

/// Branded header with the signature hanging cart logo: a white circular
/// badge with the cart icon and a live count pill that "hangs" over the
/// gradient header panel.
class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.totalQuantity});
  final int totalQuantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile, AppSpacing.md, AppSpacing.marginMobile, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowLevel2,
              blurRadius: 18,
              offset: Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x2E000000),
                      blurRadius: 12,
                      offset: Offset(0, 5))
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_cart_rounded,
                      size: 32, color: AppColors.primary),
                  if (totalQuantity > 0)
                    Positioned(
                      top: 6,
                      right: 4,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.4, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0x2E000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: Text(
                            '$totalQuantity',
                            style: AppTypography.labelLg(color: Colors.white)
                                .copyWith(
                                    fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QuickerX Cart',
                  style: AppTypography.titleLg(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w800, fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  totalQuantity > 0
                      ? '$totalQuantity item${totalQuantity == 1 ? '' : 's'} in your cart'
                      : 'Your cart is empty',
                  style: AppTypography.labelLg(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push(RoutePaths.saveForLater),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Saved',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Cascades sections in one after another: each item fades in and slides up
/// slightly, with later sections taking a touch longer so the cart contents
/// animate in like a professional shopping app. Deterministic — always ends
/// fully visible, never stuck invisible.
class _StaggerItem extends StatelessWidget {
  const _StaggerItem({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyView(
          icon: Icons.remove_shopping_cart_outlined,
          title: 'Your cart is empty',
          message:
              'Looks like you haven\'t added anything yet. Start exploring!',
          action: ElevatedButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('Continue Shopping')),
        ),
      ),
    );
  }
}

class _FreeDeliveryBar extends StatelessWidget {
  const _FreeDeliveryBar({required this.subtotal, required this.threshold});
  final double subtotal;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final remaining = threshold - subtotal;
    final unlocked = remaining <= 0;
    final progress = (subtotal / threshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primaryFixed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.base),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLevel1,
              blurRadius: 8,
              offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 18, color: AppColors.onPrimaryFixed),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  unlocked
                      ? 'You have unlocked FREE delivery'
                      : 'Add ₹${remaining.toStringAsFixed(0)} more for FREE delivery',
                  style: AppTypography.bodyMd().copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimaryFixed),
                ),
              ),
              Text(
                unlocked ? '✓' : '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTypography.labelLg(color: AppColors.onPrimaryFixed)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primaryFixedDim.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopGroupCard extends ConsumerWidget {
  const _ShopGroupCard({required this.group});
  final CartShopGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cartControllerProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLevel1,
              blurRadius: 10,
              offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.base),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.storefront_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(group.shopName,
                        style: AppTypography.bodyMd()
                            .copyWith(fontWeight: FontWeight.w800))),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text('${group.etaMinutes} mins',
                      style: AppTypography.labelLg(color: AppColors.primary)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Divider()),
          ...group.items
              .map((item) => _CartLineItem(item: item, controller: controller)),
        ],
      ),
    );
  }
}

class _CartLineItem extends StatelessWidget {
  const _CartLineItem({required this.item, required this.controller});
  final CartItemModel item;
  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.base),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.35),
                border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: item.product.imageUrl,
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 74,
                        height: 74,
                        color: AppColors.surfaceContainerHigh),
                    errorWidget: (_, __, ___) => Container(
                      width: 74,
                      height: 74,
                      color: AppColors.surfaceContainerHigh,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.outline, size: 20),
                    ),
                  ),
                  if (!item.product.inStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        alignment: Alignment.center,
                        child: Text(
                          'OUT OF STOCK',
                          style: AppTypography.labelLg(color: Colors.white)
                              .copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd()
                        .copyWith(fontWeight: FontWeight.w700)),
                if (item.variantLabel != null)
                  Text(item.variantLabel!,
                      style: AppTypography.labelLg(
                          color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('₹${item.product.price.toStringAsFixed(0)}',
                        style: AppTypography.labelLg()
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (item.product.originalPrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '₹${item.product.originalPrice!.toStringAsFixed(0)}',
                        style: AppTypography.labelLg(color: AppColors.outline)
                            .copyWith(
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w400,
                                fontSize: 11),
                      ),
                    ],
                    if (item.quantity > 1) ...[
                      const SizedBox(width: 6),
                      Text('× ${item.quantity}',
                          style: AppTypography.labelLg(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    TextButton(
                      onPressed: () => controller.moveToSavedForLater(item.id),
                      style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('Save for later',
                          style: AppTypography.labelLg(color: AppColors.primary)
                              .copyWith(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => controller.moveToWishlist(item.id),
                      style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('Move to wishlist',
                          style: AppTypography.labelLg(
                                  color: AppColors.onSurfaceVariant)
                              .copyWith(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                QuantityStepper(
                  compact: true,
                  quantity: item.quantity,
                  onIncrement: () =>
                      controller.updateQuantity(item.id, item.quantity + 1),
                  onDecrement: () =>
                      controller.updateQuantity(item.id, item.quantity - 1),
                ),
                const SizedBox(height: 8),
                Text('₹${item.lineTotal.toStringAsFixed(0)}',
                    style: AppTypography.labelLg(color: AppColors.primary)
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                IconButton(
                  onPressed: () => controller.removeItem(item.id),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponSummaryCard extends StatelessWidget {
  const _CouponSummaryCard(
      {required this.appliedCoupon, required this.orderValue});
  final CouponModel? appliedCoupon;
  final double orderValue;

  @override
  Widget build(BuildContext context) {
    final coupon = appliedCoupon;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLevel1,
              blurRadius: 10,
              offset: Offset(0, 3))
        ],
      ),
      child: GestureDetector(
        onTap: () => context.push(RoutePaths.coupons),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.base),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.sell_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon != null ? 'Coupon applied' : 'Apply Coupon',
                    style: AppTypography.bodyMd()
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    coupon != null
                        ? '${coupon.code} • ₹${coupon.discountFor(orderValue).toStringAsFixed(0)} off'
                        : 'Check available offers & coupons',
                    style: AppTypography.labelLg(
                        color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (coupon != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(coupon.code,
                    style: AppTypography.labelLg(color: AppColors.primary)
                        .copyWith(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class _StickyCheckoutBar extends StatelessWidget {
  const _StickyCheckoutBar(
      {required this.items,
      required this.appliedCoupon,
      required this.totalQuantity});
  final List<CartItemModel> items;
  final CouponModel? appliedCoupon;
  final int totalQuantity;

  CartPriceSummary get _summary {
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final mrpTotal = items.fold<double>(0, (sum, i) => sum + i.lineMrpTotal);
    return CartPriceSummary(
      subtotal: subtotal,
      discount: (mrpTotal - subtotal).clamp(0, double.infinity),
      platformFee: items.isEmpty ? 0 : 9,
      deliveryCharge: items.isEmpty ? 0 : 25,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final couponDiscount = appliedCoupon?.discountFor(summary.subtotal) ?? 0.0;
    final grandTotal = summary.grandTotal - couponDiscount;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.sm,
          AppSpacing.marginMobile, AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Payable',
                    style: AppTypography.labelLg(
                        color: AppColors.onSurfaceVariant)),
                Text(
                  '₹${grandTotal.toStringAsFixed(0)}',
                  style: AppTypography.titleLg().copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryContainer, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.push(RoutePaths.checkout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: Text('Checkout • $totalQuantity',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
