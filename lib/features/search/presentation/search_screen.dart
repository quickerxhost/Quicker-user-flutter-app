import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/search_and_nav_widgets.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../cart/application/cart_controller.dart';
import '../application/search_controller.dart';

/// Matches Stitch `search_discovery`: premium search bar (voice + image
/// search), Recent Searches chips, Trending Searches chips, Popular
/// Categories, results grid with shimmer/empty states.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (value.trim().isEmpty) {
        ref.read(searchQueryControllerProvider.notifier).clear();
      } else {
        ref.read(searchQueryControllerProvider.notifier).search(value.trim());
      }
    });
  }

  void _applyChip(String text) {
    _controller.text = text;
    ref.read(searchQueryControllerProvider.notifier).search(text);
  }

  @override
  Widget build(BuildContext context) {
    final queryState = ref.watch(searchQueryControllerProvider);
    final showDiscovery = queryState.query.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
              child: AppSearchBar(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                onSubmitted: (v) => ref.read(searchQueryControllerProvider.notifier).search(v.trim()),
                onVoiceTap: () => context.push(RoutePaths.voiceSearch),
                onScanTap: () => context.push(RoutePaths.barcodeScanner),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: showDiscovery
                  ? _DiscoveryContent(onChipTap: _applyChip)
                  : _ResultsGrid(state: queryState),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryContent extends ConsumerWidget {
  const _DiscoveryContent({required this.onChipTap});
  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);
    final trending = ref.watch(trendingSearchesProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      children: [
        recent.when(
          data: (items) => items.isEmpty
              ? const SizedBox.shrink()
              : _ChipSection(title: 'Recent Searches', icon: Icons.history_rounded, items: items, onChipTap: onChipTap),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.lg),
        trending.when(
          data: (items) => _ChipSection(title: 'Trending Searches', icon: Icons.trending_up_rounded, items: items, onChipTap: onChipTap),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({required this.title, required this.icon, required this.items, required this.onChipTap});
  final String title;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(title, style: AppTypography.labelLg(color: AppColors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => ActionChip(
                    label: Text(item),
                    backgroundColor: AppColors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    side: BorderSide.none,
                    onPressed: () => onChipTap(item),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _ResultsGrid extends ConsumerWidget {
  const _ResultsGrid({required this.state});
  final SearchQueryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Padding(padding: EdgeInsets.all(AppSpacing.marginMobile), child: ProductGridShimmer());
    }
    if (state.errorMessage != null) {
      return AppErrorView(message: state.errorMessage!);
    }
    if (state.results.isEmpty) {
      return EmptyView(
        icon: Icons.search_off_rounded,
        title: 'No results for "${state.query}"',
        message: 'Try a different search term or browse categories instead.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      itemCount: state.results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        final product = state.results[index];
        return GestureDetector(
          onTap: () => context.push('${RoutePaths.productDetails}/${product.id}', extra: product),
          child: ProductCard(
            product: product,
            onAddToCart: () async {
              await ref.read(cartControllerProvider.notifier).addProduct(product, shopId: 'demo-shop', shopName: 'QuickerX Store');
            },
            onRemoveFromCart: () => ref.read(cartControllerProvider.notifier).decrementProduct(product.id),
          ),
        );
      },
    );
  }
}
