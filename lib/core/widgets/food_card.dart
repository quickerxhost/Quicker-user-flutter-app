import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../features/restaurant_menu/domain/models/food_item_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'veg_non_veg_badge.dart';

/// Menu-list row: veg/non-veg badge + tags, name, description snippet,
/// price, thumbnail with an overlaid ADD button (shows "Customizable" if
/// the item has add-on groups) — matches Stitch `the_spice_hub_menu`.
class FoodCard extends StatelessWidget {
  const FoodCard({super.key, required this.food, this.onTap, this.onAdd, this.quantity = 0, this.onIncrement, this.onDecrement});

  final FoodItemModel food;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  String get _tagLabel {
    if (food.tags.contains(FoodTag.bestseller)) return 'Bestseller';
    if (food.tags.contains(FoodTag.mustTry)) return 'Must Try';
    if (food.tags.contains(FoodTag.trending)) return 'Trending';
    if (food.tags.contains(FoodTag.recommended)) return 'Recommended';
    if (food.tags.contains(FoodTag.popular)) return 'Popular';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VegNonVegBadge(purity: food.purity),
                      if (_tagLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(_tagLabel, style: AppTypography.labelLg(color: AppColors.secondaryContainer).copyWith(fontSize: 11)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(food.name, style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('₹${food.price.toStringAsFixed(0)}', style: AppTypography.bodyMd().copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    food.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 110,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.image),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        imageUrl: food.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surfaceContainerHigh),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceContainerHigh,
                          child: const Icon(Icons.fastfood_rounded, color: AppColors.outline, size: 28),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -14),
                    child: _AddControl(
                      quantity: quantity,
                      hasCustomization: food.hasCustomization,
                      onAdd: onAdd,
                      onIncrement: onIncrement,
                      onDecrement: onDecrement,
                    ),
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

class _AddControl extends StatelessWidget {
  const _AddControl({required this.quantity, required this.hasCustomization, this.onAdd, this.onIncrement, this.onDecrement});
  final int quantity;
  final bool hasCustomization;
  final VoidCallback? onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    if (quantity <= 0) {
      return SizedBox(
        width: 90,
        child: ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceContainerLowest,
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.outlineVariant),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            elevation: 2,
          ),
          child: Text(hasCustomization ? 'ADD +' : 'ADD', style: AppTypography.labelLg(color: AppColors.primary).copyWith(fontSize: 12)),
        ),
      );
    }
    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(onTap: onDecrement, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Icon(Icons.remove_rounded, size: 14, color: Colors.white))),
          Text('$quantity', style: AppTypography.labelLg(color: Colors.white).copyWith(fontSize: 12)),
          InkWell(onTap: onIncrement, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Icon(Icons.add_rounded, size: 14, color: Colors.white))),
        ],
      ),
    );
  }
}
