import 'package:flutter/material.dart';
import '../../features/restaurants/domain/models/restaurant_model.dart';

/// The standard Indian food-delivery-app veg/non-veg indicator: a small
/// square outline with a colored dot inside (green for veg, brown/red for
/// non-veg). Used on [RestaurantCard], [FoodCard], and Food Details.
class VegNonVegBadge extends StatelessWidget {
  const VegNonVegBadge({super.key, required this.purity, this.size = 16});
  final FoodPurity purity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isVeg = purity == FoodPurity.veg || purity == FoodPurity.pureVeg;
    final color = isVeg ? const Color(0xFF0F8A0F) : const Color(0xFF8A0F0F);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.15),
      decoration: BoxDecoration(border: Border.all(color: color, width: 1.4), borderRadius: BorderRadius.circular(2)),
      child: Center(
        child: Container(
          decoration: BoxDecoration(color: color, shape: isVeg ? BoxShape.circle : BoxShape.circle),
        ),
      ),
    );
  }
}
