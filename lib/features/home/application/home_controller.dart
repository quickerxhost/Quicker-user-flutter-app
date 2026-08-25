import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/repositories/home_repository.dart';
import '../domain/models/home_feed_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    ref.watch(dioClientProvider),
    ref.watch(locationServiceProvider),
    ref.watch(secureStorageProvider),
  );
});

final homeFeedProvider = AsyncNotifierProvider<HomeFeedController, HomeFeedModel>(HomeFeedController.new);

class HomeFeedController extends AsyncNotifier<HomeFeedModel> {
  @override
  Future<HomeFeedModel> build() async {
    final repository = ref.read(homeRepositoryProvider);
    final result = await repository.getHomeFeed();
    return result.when(
      success: (feed) => feed,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading<HomeFeedModel>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final repository = ref.read(homeRepositoryProvider);
      final result = await repository.getHomeFeed();
      return result.when(success: (feed) => feed, failure: (error) => throw error);
    });
  }

  void toggleWishlist(String productId) {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.trendingProducts
        .map((p) => p.id == productId ? p.copyWith(isWishlisted: !p.isWishlisted) : p)
        .toList();
    state = AsyncValue.data(HomeFeedModel(
      greetingName: current.greetingName,
      hub: current.hub,
      categories: current.categories,
      banners: current.banners,
      trendingProducts: updated,
    ));
  }
}
