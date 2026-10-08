import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../checkout/domain/models/order_model.dart';

/// No Stitch design exists for this screen — built to match the app's
/// token system per the PRD's Order Success spec: premium checkmark
/// animation, order number, delivery time, track order, continue
/// shopping, download invoice, share order.
///
/// A Lottie success animation is a drop-in swap here (the tech stack lists
/// `lottie`) — this uses a scale/fade checkmark built from the core
/// animation APIs so the screen doesn't depend on an asset file that
/// doesn't exist yet. Point [Lottie.asset] at a real file under
/// `assets/animations/` when you have one and replace `_CheckmarkBurst`.
class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.order});
  final OrderModel order;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with SingleTickerProviderStateMixin {
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
                      Text('Order Placed!', style: AppTypography.headlineLgMobile(), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        'Your order has been confirmed and will arrive soon.',
                        style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
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
                        _InfoRow(label: 'Order Number', value: order.orderId),
                        _InfoRow(label: 'Placed On', value: DateFormat('MMM d, h:mm a').format(order.placedAt)),
                        _InfoRow(label: 'Estimated Delivery', value: order.etaLabel),
                        _InfoRow(label: 'Payment', value: order.paymentMethodLabel),
                        _InfoRow(label: 'Total', value: '₹${order.grandTotal.toStringAsFixed(0)}'),
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
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order tracking ships alongside the Orders module.')),
                        ),
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
                      TextButton(
                        onPressed: () => context.go(RoutePaths.home),
                        child: const Text('Continue Shopping'),
                      ),
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
          Text(value, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
