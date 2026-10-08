import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Base shimmer box — compose these into skeleton layouts per screen.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerLowest,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Skeleton matching [ProductCard]'s footprint, for grid/list loading.
class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ShimmerBox(width: double.infinity, height: double.infinity, radius: AppRadius.image),
        ),
        SizedBox(height: 8),
        ShimmerBox(width: double.infinity, height: 14),
        SizedBox(height: 6),
        ShimmerBox(width: 80, height: 14),
        SizedBox(height: 6),
        ShimmerBox(width: 60, height: 16),
      ],
    );
  }
}

/// Skeleton grid for product listing / home trending sections.
class ProductGridShimmer extends StatelessWidget {
  const ProductGridShimmer({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.56,
      ),
      itemBuilder: (context, index) => const ProductCardShimmer(),
    );
  }
}
