import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cart/application/cart_controller.dart';
import '../../features/home/domain/models/product_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'quantity_stepper.dart';

/// Product tile used on Home ("Trending Near You"), Search ("Top Picks") and
/// the Product Listing grid — beautiful card with elevation, gradient accents,
/// smooth animations, and polished visual details.
class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onRemoveFromCart,
    this.onToggleWishlist,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onRemoveFromCart;
  final VoidCallback? onToggleWishlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartControllerProvider).valueOrNull ?? [];
    final quantity =
        cartItems.where((item) => item.product.id == product.id).fold<int>(0, (sum, item) => sum + item.quantity);
    final showAddControl = onAddToCart != null;
    final outOfStock = !product.inStock;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                // Image with subtle gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryFixed.withValues(alpha: 0.1),
                        AppColors.primaryFixed.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => Container(
                        color: AppColors.surfaceContainerHighest,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.outline,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                // Discount badge
                if (product.discountLabel != null && product.inStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondaryContainer, AppColors.primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        product.discountLabel!,
                        style: AppTypography.labelLg(color: Colors.white).copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                // Out of stock overlay
                if (outOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'OUT OF STOCK',
                            style: AppTypography.labelLg(color: AppColors.error).copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Wishlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onToggleWishlist,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          product.isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: product.isWishlisted ? AppColors.error : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                  // Meta
                  if (product.meta != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 10,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.meta!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)
                                .copyWith(fontWeight: FontWeight.w500, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Price & Add to cart
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: AppTypography.labelLg(color: AppColors.primary).copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (product.originalPrice != null) ...[
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '₹${product.originalPrice!.toStringAsFixed(0)}',
                                  style: AppTypography.labelLg(color: AppColors.outline).copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (showAddControl && !outOfStock)
                        quantity > 0
                            ? QuantityStepper(
                                compact: true,
                                quantity: quantity,
                                onIncrement: onAddToCart!,
                                onDecrement: onRemoveFromCart ?? () {},
                              )
                            : _AddToCartButton(onTap: onAddToCart!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beautiful ADD button with subtle press animation
class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryContainer, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            'ADD',
            style: AppTypography.labelLg(color: Colors.white).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}