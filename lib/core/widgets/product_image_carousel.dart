import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Swipeable, pinch-to-zoom image carousel for Product Details. Each image
/// is wrapped in [InteractiveViewer] for pinch-to-zoom, and the first image
/// carries a [Hero] tag so tapping into this screen from a [ProductCard]
/// animates smoothly.
class ProductImageCarousel extends StatefulWidget {
  const ProductImageCarousel({super.key, required this.imageUrls, required this.heroTag});
  final List<String> imageUrls;
  final String heroTag;

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls.isEmpty ? [''] : widget.imageUrls;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final child = ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.image),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.surfaceContainerHigh),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.outline),
                  ),
                ),
              );
              return InteractiveViewer(
                minScale: 1,
                maxScale: 3,
                child: index == 0 ? Hero(tag: widget.heroTag, child: child) : child,
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
