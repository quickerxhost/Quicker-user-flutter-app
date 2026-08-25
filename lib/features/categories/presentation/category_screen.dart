import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_views.dart';
import '../data/repositories/category_repository.dart';

/// No Stitch design exists for this screen — built with the shared
/// `CategoryCard` visual language (circular icon + label) laid out as a
/// grid per the PRD's "Beautiful Grid / Images / Icons / Category
/// Animation" spec.
final categoryRepositoryProvider = Provider((ref) => CategoryRepository(ref.watch(dioClientProvider)));

final allCategoriesProvider = FutureProvider((ref) async {
  final result = await ref.watch(categoryRepositoryProvider).getAllCategories();
  return result.when(success: (v) => v, failure: (e) => throw e);
});

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Categories')),
      body: categoriesAsync.when(
        data: (categories) => GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _AnimatedCategoryTile(
              index: index,
              child: GestureDetector(
                onTap: () => context.push(
                  RoutePaths.productListing,
                  extra: {'categoryId': category.id, 'categoryName': category.name},
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Icon(category.icon, size: 30, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLg(color: AppColors.onSurfaceVariant).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (error, _) => AppErrorView(message: error.toString(), onRetry: () => ref.invalidate(allCategoriesProvider)),
      ),
    );
  }
}

/// Small staggered fade/scale-in per grid item — the "Category Animation"
/// called out in the PRD.
class _AnimatedCategoryTile extends StatefulWidget {
  const _AnimatedCategoryTile({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_AnimatedCategoryTile> createState() => _AnimatedCategoryTileState();
}

class _AnimatedCategoryTileState extends State<_AnimatedCategoryTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    Future.delayed(Duration(milliseconds: 30 * (widget.index % 15)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: FadeTransition(opacity: _animation, child: widget.child));
  }
}
