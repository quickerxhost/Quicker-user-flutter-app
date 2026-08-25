import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../application/restaurant_orders_controller.dart';
import '../domain/models/restaurant_order_model.dart';

/// Matches Stitch `tracking_your_meal`: live map with rider marker, order
/// timeline (Preparing -> Picked Up -> Out for Delivery -> Delivered),
/// delivery OTP, Call Rider / Chat / Restaurant Contact actions.
///
/// `ApiEndpoints.liveTracking` is blank, so the rider's position/status is
/// simulated via [RestaurantOrdersRepository.watchOrderStatus] — swap that
/// stream for a real socket feed later; this screen only depends on the
/// stream's `RestaurantOrderModel` shape.
class RestaurantTrackingScreen extends ConsumerWidget {
  const RestaurantTrackingScreen({super.key, required this.order});
  final RestaurantOrderModel order;

  static const _defaultCenter = LatLng(19.0760, 72.8777); // Mumbai fallback center for the demo map

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingAsync = ref.watch(restaurantOrderTrackingProvider(order));
    final current = trackingAsync.valueOrNull ?? order;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${current.orderId}'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(target: _defaultCenter, zoom: 14),
                  zoomControlsEnabled: false,
                  liteModeEnabled: true,
                  markers: {
                    const Marker(markerId: MarkerId('rider'), position: _defaultCenter, infoWindow: InfoWindow(title: 'Your rider')),
                  },
                ),
                if (current.status == RestaurantOrderStatus.pickedUp || current.status == RestaurantOrderStatus.outForDelivery)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.base), boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10)]),
                      child: Text('Arriving in ${current.etaLabel}', style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                _OrderTimeline(status: current.status),
                const SizedBox(height: AppSpacing.lg),
                if (current.deliveryOtp != null && current.status != RestaurantOrderStatus.delivered)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(AppRadius.base)),
                    child: Row(
                      children: [
                        const Icon(Icons.password_rounded, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text('Share this OTP with your rider on delivery', style: AppTypography.bodyMd())),
                        Text(current.deliveryOtp!, style: AppTypography.headlineLgMobile(color: AppColors.primary).copyWith(fontSize: 22)),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                if (current.rider != null) _RiderCard(rider: current.rider!),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.base)),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(current.restaurantName, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
                            Text(current.restaurantAddress, style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling ${current.restaurantPhone}'))),
                        icon: const Icon(Icons.call_outlined, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({required this.rider});
  final RiderModel rider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.base)),
      child: Row(
        children: [
          const CircleAvatar(radius: 22, backgroundColor: AppColors.primaryFixed, child: Icon(Icons.delivery_dining_rounded, color: AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(rider.name, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.secondaryContainer),
                    Text(rider.rating.toStringAsFixed(1), style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
                  ],
                ),
                Text(rider.vehicleLabel, style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling ${rider.name}'))),
            icon: const Icon(Icons.call_outlined, color: AppColors.primary),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat opens once messaging is wired to the backend.'))),
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.status});
  final RestaurantOrderStatus status;

  static const _steps = [
    (status: RestaurantOrderStatus.preparing, label: 'Preparing', icon: Icons.soup_kitchen_outlined),
    (status: RestaurantOrderStatus.pickedUp, label: 'Picked Up', icon: Icons.shopping_bag_outlined),
    (status: RestaurantOrderStatus.outForDelivery, label: 'Out for Delivery', icon: Icons.delivery_dining_rounded),
    (status: RestaurantOrderStatus.delivered, label: 'Delivered', icon: Icons.home_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexWhere((s) => s.status == status);

    return Column(
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final done = currentIndex >= i;
        final isLast = i == _steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: done ? AppColors.primary : AppColors.surfaceContainerLow, shape: BoxShape.circle),
                  child: Icon(step.icon, size: 16, color: done ? Colors.white : AppColors.outline),
                ),
                if (!isLast) Container(width: 2, height: 36, color: done && currentIndex > i ? AppColors.primary : AppColors.outlineVariant),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(step.label, style: AppTypography.bodyMd(color: done ? AppColors.onSurface : AppColors.outline).copyWith(fontWeight: done ? FontWeight.w600 : FontWeight.w400)),
            ),
          ],
        );
      }),
    );
  }
}
