import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Horizontal scrollable pill-tab row used for the menu's sticky category
/// navigation (Recommended / Starters / Main Course / Desserts...).
class MenuCategoryTabs extends StatelessWidget {
  const MenuCategoryTabs({super.key, required this.categories, required this.activeId, required this.onSelect});
  final List<({String id, String title})> categories;
  final String? activeId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = category.id == activeId;
          return GestureDetector(
            onTap: () => onSelect(category.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                category.title,
                style: AppTypography.labelLg(color: active ? Colors.white : AppColors.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A [SliverPersistentHeaderDelegate] wrapper so [MenuCategoryTabs] can
/// pin to the top of a `CustomScrollView` while scrolling the menu.
class StickyTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  StickyTabsHeaderDelegate({required this.child, this.height = 48});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(color: AppColors.surface, elevation: overlapsContent ? 2 : 0, child: child);
  }

  @override
  bool shouldRebuild(covariant StickyTabsHeaderDelegate oldDelegate) => oldDelegate.child != child;
}
