import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';
import '../application/cart_controller.dart';

/// No Stitch design exists for this screen — built to match the app's
/// token system per the PRD's "Save For Later" spec: product list,
/// move-to-cart, delete.
class SaveForLaterScreen extends ConsumerWidget {
  const SaveForLaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedForLaterControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved for Later')),
      body: savedAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => AppErrorView(message: error.toString(), onRetry: () => ref.invalidate(savedForLaterControllerProvider)),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(
              icon: Icons.bookmark_border_rounded,
              title: 'Nothing saved for later',
              message: 'Items you save from your cart will show up here.',
              action: ElevatedButton(onPressed: () => context.go(RoutePaths.home), child: const Text('Continue Shopping')),
            );
          }
          final controller = ref.read(savedForLaterControllerProvider.notifier);
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(AppRadius.base)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: CachedNetworkImage(
                        imageUrl: item.product.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: AppColors.surfaceContainerHigh,
                          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.outline, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
                          Text('₹${item.product.price.toStringAsFixed(0)}', style: AppTypography.labelLg()),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => controller.moveToCart(item.id), icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary)),
                    IconButton(onPressed: () => controller.remove(item.id), icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
