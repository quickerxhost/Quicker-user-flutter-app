import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/food_card.dart';
import '../../../core/widgets/restaurant_card.dart';
import '../../../core/widgets/search_and_nav_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../application/restaurant_search_controller.dart';

/// No dedicated Stitch design exists for this screen — built to match the
/// app's token system (and the general Search screen's layout language)
/// per the PRD's Restaurant Search spec: trending/recent searches,
/// combined restaurant + food results, voice search. "Image Search Ready"
/// from the tech stack means the search bar already exposes a hook
/// (`onScanTap`) an ML-Kit-backed image search can attach to later — no
/// ML Kit dependency is wired yet since no image-search screen exists in
/// this PRD's screen list.
class RestaurantSearchScreen extends ConsumerStatefulWidget {
  const RestaurantSearchScreen({super.key});

  @override
  ConsumerState<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends ConsumerState<RestaurantSearchScreen> {
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
        ref.read(restaurantSearchControllerProvider.notifier).clear();
      } else {
        ref.read(restaurantSearchControllerProvider.notifier).search(value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantSearchControllerProvider);
    final controller = ref.read(restaurantSearchControllerProvider.notifier);
    final showDiscovery = state.query.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Search Restaurants & Food')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
              child: AppSearchBar(
                controller: _controller,
                autofocus: true,
                hintText: 'Search restaurants, cuisines, dishes',
                onChanged: _onChanged,
                onSubmitted: (v) => controller.search(v.trim()),
                onVoiceTap: () => context.push(RoutePaths.voiceSearch),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: showDiscovery
                  ? _Discovery(
                      recent: controller.recentSearches,
                      trending: controller.trendingSearches,
                      onChipTap: (v) {
                        _controller.text = v;
                        controller.search(v);
                      },
                    )
                  : _Results(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

class _Discovery extends StatelessWidget {
  const _Discovery({required this.recent, required this.trending, required this.onChipTap});
  final List<String> recent;
  final List<String> trending;
  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      children: [
        _ChipSection(title: 'Recent Searches', icon: Icons.history_rounded, items: recent, onChipTap: onChipTap),
        const SizedBox(height: AppSpacing.lg),
        _ChipSection(title: 'Trending Searches', icon: Icons.trending_up_rounded, items: trending, onChipTap: onChipTap),
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
        Row(children: [Icon(icon, size: 18, color: AppColors.onSurfaceVariant), const SizedBox(width: 6), Text(title, style: AppTypography.labelLg(color: AppColors.onSurfaceVariant))]),
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

class _Results extends StatelessWidget {
  const _Results({required this.state});
  final RestaurantSearchState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const LoadingView();
    if (state.errorMessage != null) return AppErrorView(message: state.errorMessage!);
    if (state.restaurantResults.isEmpty && state.foodResults.isEmpty) {
      return EmptyView(icon: Icons.search_off_rounded, title: 'No results for "${state.query}"', message: 'Try a different search term.');
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        if (state.foodResults.isNotEmpty) ...[
          Text('Food', style: AppTypography.titleLg().copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          ...state.foodResults.map((food) => FoodCard(food: food)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (state.restaurantResults.isNotEmpty) ...[
          Text('Restaurants', style: AppTypography.titleLg().copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.sm),
          ...state.restaurantResults.map((restaurant) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: RestaurantCard(restaurant: restaurant, onTap: () => context.push('${RoutePaths.restaurantDetails}/${restaurant.id}')),
              )),
        ],
      ],
    );
  }
}
