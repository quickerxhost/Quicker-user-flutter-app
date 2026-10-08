import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/models/restaurant_order_model.dart';

/// Matches Stitch `order_confirmed_restaurant`: premium checkmark
/// animation, order ID, restaurant name, ETA, track order, download
/// invoice, share order, continue shopping.
class RestaurantOrderSuccessScreen extends StatefulWidget {
  const RestaurantOrderSuccessScreen({super.key, required this.order});
  final RestaurantOrderModel order;

  @override
  State<RestaurantOrderSuccessScreen> createState() => _RestaurantOrderSuccessScreenState();
}

class _RestaurantOrderSuccessScreenState extends State<RestaurantOrderSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1, curve: Curves.easeIn));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Column(
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      Text('Order Confirmed!', style: AppTypography.headlineLgMobile(), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text('${order.restaurantName} is preparing your order.', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeTransition(
                  opacity: _fade,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.base)),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Order ID', value: order.orderId),
                        _InfoRow(label: 'Restaurant', value: order.restaurantName),
                        _InfoRow(label: 'Placed On', value: DateFormat('MMM d, h:mm a').format(order.placedAt)),
                        _InfoRow(label: 'Estimated Arrival', value: order.etaLabel),
                        _InfoRow(label: 'Total', value: '₹${order.grandTotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Track Order',
                        trailingIcon: Icons.local_shipping_outlined,
                        onPressed: () => context.go(RoutePaths.restaurantTracking, extra: order),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invoice download requires a backend PDF endpoint.')),
                              ),
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Invoice'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Order ${order.orderId} link copied to share.')),
                              ),
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Share'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(onPressed: () => context.go(RoutePaths.restaurantHome), child: const Text('Continue Shopping')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
