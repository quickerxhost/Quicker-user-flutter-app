import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';
import '../application/restaurant_orders_controller.dart';
import '../domain/models/restaurant_order_model.dart';

/// No dedicated Stitch design exists for this screen — built to match the
/// app's token system per the PRD's Restaurant Orders spec: Active / Past
/// / Cancelled tabs, repeat order, download invoice, rate restaurant/rate
/// delivery.
class RestaurantOrdersScreen extends ConsumerStatefulWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  ConsumerState<RestaurantOrdersScreen> createState() => _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends ConsumerState<RestaurantOrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(restaurantOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Past'), Tab(text: 'Cancelled')],
        ),
      ),
      body: ordersAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => AppErrorView(message: error.toString(), onRetry: () => ref.invalidate(restaurantOrdersProvider)),
        data: (orders) => TabBarView(
          controller: _tabController,
          children: [
            _OrdersList(orders: filterOrdersByTab(orders, RestaurantOrderTab.active)),
            _OrdersList(orders: filterOrdersByTab(orders, RestaurantOrderTab.past), showRepeatAndRate: true),
            _OrdersList(orders: filterOrdersByTab(orders, RestaurantOrderTab.cancelled)),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders, this.showRepeatAndRate = false});
  final List<RestaurantOrderModel> orders;
  final bool showRepeatAndRate;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const EmptyView(icon: Icons.receipt_long_outlined, title: 'No orders here', message: 'Orders in this category will show up here.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _OrderCard(order: orders[index], showRepeatAndRate: showRepeatAndRate),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.showRepeatAndRate});
  final RestaurantOrderModel order;
  final bool showRepeatAndRate;

  Color get _statusColor => switch (order.status) {
        RestaurantOrderStatus.delivered => const Color(0xFF0F8A0F),
        RestaurantOrderStatus.cancelled => AppColors.error,
        _ => AppColors.secondaryContainer,
      };

  String get _statusLabel => switch (order.status) {
        RestaurantOrderStatus.placed => 'Order Placed',
        RestaurantOrderStatus.accepted => 'Accepted',
        RestaurantOrderStatus.preparing => 'Preparing',
        RestaurantOrderStatus.pickedUp => 'Picked Up',
        RestaurantOrderStatus.outForDelivery => 'Out for Delivery',
        RestaurantOrderStatus.delivered => 'Delivered',
        RestaurantOrderStatus.cancelled => 'Cancelled',
      };

  @override
  Widget build(BuildContext context) {
    final isActive = order.status != RestaurantOrderStatus.delivered && order.status != RestaurantOrderStatus.cancelled;
    final actionButtons = <Widget>[];
    if (isActive) {
      actionButtons.add(Expanded(child: OutlinedButton(onPressed: () => context.push(RoutePaths.restaurantTracking, extra: order), child: const Text('Track Order'))));
    }
    if (showRepeatAndRate) {
      if (actionButtons.isNotEmpty) actionButtons.add(const SizedBox(width: AppSpacing.sm));
      actionButtons.add(Expanded(
        child: OutlinedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Repeating order from ${order.restaurantName}...'))),
          child: const Text('Repeat Order'),
        ),
      ));
      actionButtons.add(const SizedBox(width: AppSpacing.sm));
      actionButtons.add(Expanded(
        child: OutlinedButton(
          onPressed: () => context.push('${RoutePaths.restaurantReviews}?restaurantId=${order.restaurantId}'),
          child: const Text('Rate Order'),
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.base)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(order.restaurantName, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w700))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Text(_statusLabel, style: AppTypography.labelLg(color: _statusColor).copyWith(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${order.itemCount} items • ₹${order.grandTotal.toStringAsFixed(0)}', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
          Text(DateFormat('MMM d, h:mm a').format(order.placedAt), style: AppTypography.labelLg(color: AppColors.outline)),
          if (actionButtons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(children: actionButtons),
          ],
        ],
      ),
    );
  }
}
