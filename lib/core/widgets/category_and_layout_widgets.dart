import 'package:flutter/material.dart';
import '../../features/home/domain/models/category_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Rounded icon-in-circle category tile used on Home "Browse Categories"
/// and the Onboarding chip row.
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, this.onTap, this.selected = false});

  final CategoryModel category;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: selected ? null : Border.all(color: AppColors.outlineVariant, width: 1),
            ),
            child: Icon(
              category.icon,
              color: selected ? AppColors.onPrimary : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          SizedBox(
            width: 72,
            child: Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Section Title" + optional "View All" row used throughout Home/Search.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.leadingIcon,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 20, color: AppColors.secondaryContainer),
          const SizedBox(width: 6),
        ],
        Expanded(child: Text(title, style: AppTypography.titleLg())),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
            child: Text(actionLabel!, style: AppTypography.labelLg(color: AppColors.primary)),
          ),
      ],
    );
  }
}

/// Bordered pill radius container used for "CURRENT HUB" and info cards.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.radius = AppRadius.md,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}
