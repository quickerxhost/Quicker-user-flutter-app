import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/misc_badges_and_cards.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/product_image_carousel.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/application/cart_controller.dart';
import '../../home/application/home_controller.dart';
import '../../home/domain/models/product_model.dart';
import '../../wishlist/application/wishlist_controller.dart';
import '../application/product_details_controller.dart';
import '../domain/models/product_detail_model.dart';

/// Full Product Details spec: image carousel with pinch-to-zoom + Hero
/// animation, pricing/discount block, delivery hub card,
/// description/specs/ingredients/nutrition, reviews, related products,
/// sticky bottom add-to-cart bar with animated quantity stepper.
///
/// When navigated from a product card the live catalog [product] is passed
/// through and the detail is built from the real product; otherwise (deep
/// links) it falls back to the detail backend / fixture data.
class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen(
      {super.key, required this.productId, this.product});
  final String productId;
  final ProductModel? product;

  String get _heroTag => 'product-image-$productId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplied = product;
    final detailAsync = supplied != null
        ? ref.watch(homeFeedProvider).maybeWhen(
              data: (feed) => AsyncData(
                ProductDetailModel.fromProduct(
                  supplied,
                  hubName: feed.hub.name,
                  etaLabel: '${feed.hub.etaMinutes} Mins',
                ),
              ),
              orElse: () => ref.watch(productDetailProvider(productId)),
            )
        : ref.watch(productDetailProvider(productId));
    final quantity = ref.watch(productQuantityProvider(productId));
    final isWishlisted = ref.watch(wishlistControllerProvider.select(
      (state) => state.valueOrNull?.any((p) => p.id == productId) ?? false,
    ));
    final hubId = ref.watch(homeFeedProvider).valueOrNull?.hub.id ?? 'hub';

    return Scaffold(
      body: detailAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => AppErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(productDetailProvider(productId))),
        data: (detail) => _DetailBody(
            detail: detail, heroTag: _heroTag, isWishlisted: isWishlisted),
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (detail) => _StickyAddToCartBar(
            detail: detail, quantity: quantity, hubId: hubId),
        orElse: () => null,
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody(
      {required this.detail,
      required this.heroTag,
      required this.isWishlisted});
  final ProductDetailModel detail;
  final String heroTag;
  final bool isWishlisted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(relatedProductsProvider(detail.base.id));
    final fbt = ref.watch(frequentlyBoughtTogetherProvider(detail.base.id));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.surface,
            pinned: true,
            leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded)),
            actions: [
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.share_outlined)),
              IconButton(
                onPressed: () => ref
                    .read(wishlistControllerProvider.notifier)
                    .toggle(detail.base),
                icon: Icon(
                    isWishlisted
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color:
                        isWishlisted ? AppColors.error : AppColors.onSurface),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              child: ProductImageCarousel(
                  imageUrls: detail.imageUrls, heroTag: heroTag),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (detail.recentlyBought)
                        const OfferChip(
                            label: 'Recently Bought',
                            icon: Icons.history_rounded),
                      if (detail.recentlyBought) const SizedBox(width: 8),
                      if (!detail.inStock)
                        const ProductBadge(
                            label: 'OUT OF STOCK', color: AppColors.error),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(detail.brand.toUpperCase(),
                      style: AppTypography.labelLg(color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text(detail.base.name,
                      style: AppTypography.headlineLgMobile()
                          .copyWith(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(detail.weight,
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${detail.base.price.toStringAsFixed(0)}',
                          style: AppTypography.headlineLgMobile()
                              .copyWith(fontSize: 26)),
                      if (detail.base.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'MRP ₹${detail.base.originalPrice!.toStringAsFixed(0)}',
                            style:
                                AppTypography.bodyMd(color: AppColors.outline)
                                    .copyWith(
                                        decoration: TextDecoration.lineThrough),
                          ),
                        ),
                      ],
                      if (detail.base.discountLabel != null) ...[
                        const SizedBox(width: 8),
                        Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: ProductBadge(
                                label: detail.base.discountLabel!)),
                      ],
                    ],
                  ),
                  if (detail.youSave > 0)
                    Text('You save ₹${detail.youSave.toStringAsFixed(0)}',
                        style: AppTypography.labelLg(color: AppColors.primary)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 18, color: AppColors.secondaryContainer),
                      const SizedBox(width: 4),
                      Text(
                          '${detail.averageRating} (${detail.reviewCount} reviews)',
                          style: AppTypography.bodyMd()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DeliveryTimeCard(
                      etaLabel: detail.etaLabel,
                      hubName: detail.deliveryHubName),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Description',
                      style: AppTypography.titleLg().copyWith(fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(detail.description,
                      style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Specifications',
                      style: AppTypography.titleLg().copyWith(fontSize: 17)),
                  const SizedBox(height: 8),
                  ...detail.specifications.entries
                      .map((e) => _SpecRow(label: e.key, value: e.value)),
                  if (detail.ingredients != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text('Ingredients',
                        style: AppTypography.titleLg().copyWith(fontSize: 17)),
                    const SizedBox(height: 8),
                    Text(detail.ingredients!.join(', '),
                        style: AppTypography.bodyMd(
                            color: AppColors.onSurfaceVariant)),
                  ],
                  if (detail.nutritionFacts != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text('Nutrition Facts',
                        style: AppTypography.titleLg().copyWith(fontSize: 17)),
                    const SizedBox(height: 8),
                    ...detail.nutritionFacts!.entries
                        .map((e) => _SpecRow(label: e.key, value: e.value)),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Text('Customer Reviews',
                          style:
                              AppTypography.titleLg().copyWith(fontSize: 17)),
                      const Spacer(),
                      Text('${detail.averageRating} ★',
                          style: AppTypography.bodyMd(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...detail.reviews.map((r) => _ReviewTile(review: r)),
                ],
              ),
            ),
          ),
          if (fbt.valueOrNull != null && fbt.valueOrNull!.isNotEmpty)
            SliverToBoxAdapter(
                child: _ProductRow(
                    title: 'Frequently Bought Together',
                    products: fbt.valueOrNull!)),
          if (related.valueOrNull != null && related.valueOrNull!.isNotEmpty)
            SliverToBoxAdapter(
                child: _ProductRow(
                    title: 'Similar Products', products: related.valueOrNull!)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style:
                      AppTypography.bodyMd(color: AppColors.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  style: AppTypography.bodyMd()
                      .copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.base)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(review.authorName,
                  style: AppTypography.bodyMd()
                      .copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < review.rating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 14,
                          color: AppColors.secondaryContainer,
                        )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(review.comment,
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.title, required this.products});
  final String title;
  final List products;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            child: Text(title,
                style: AppTypography.titleLg().copyWith(fontSize: 17)),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 280,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final product = products[index];
                return SizedBox(
                  width: 150,
                  child: GestureDetector(
                    onTap: () => context.push(
                        '${RoutePaths.productDetails}/${product.id}',
                        extra: product),
                    child: ProductCard(product: product),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyAddToCartBar extends ConsumerWidget {
  const _StickyAddToCartBar(
      {required this.detail, required this.quantity, required this.hubId});
  final ProductDetailModel detail;
  final int quantity;
  final String hubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile, vertical: AppSpacing.sm),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            QuantityStepper(
              quantity: quantity,
              onIncrement: () => ref
                  .read(productQuantityProvider(detail.base.id).notifier)
                  .state = quantity + 1,
              onDecrement: () => ref
                  .read(productQuantityProvider(detail.base.id).notifier)
                  .state = (quantity - 1).clamp(0, 99),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
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
                child: ElevatedButton(
                  onPressed: !detail.inStock
                      ? null
                      : () async {
                          await ref
                              .read(cartControllerProvider.notifier)
                              .addProduct(
                                detail.base,
                                shopId: hubId,
                                shopName: detail.deliveryHubName,
                                quantity: quantity.clamp(1, 99),
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full)),
                  ),
                  child: Text(
                    detail.inStock ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
