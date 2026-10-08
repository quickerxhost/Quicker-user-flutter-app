import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../home/domain/models/product_model.dart';
import '../data/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(dioClientProvider));
});

final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final result = await ref.watch(searchRepositoryProvider).getRecentSearches();
  return result.when(success: (v) => v, failure: (_) => const []);
});

final trendingSearchesProvider = FutureProvider<List<String>>((ref) async {
  final result = await ref.watch(searchRepositoryProvider).getTrendingSearches();
  return result.when(success: (v) => v, failure: (_) => const []);
});

class SearchQueryState {
  final String query;
  final bool isLoading;
  final List<ProductModel> results;
  final String? errorMessage;

  const SearchQueryState({this.query = '', this.isLoading = false, this.results = const [], this.errorMessage});

  SearchQueryState copyWith({String? query, bool? isLoading, List<ProductModel>? results, String? errorMessage}) {
    return SearchQueryState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      errorMessage: errorMessage,
    );
  }
}

final searchQueryControllerProvider =
    StateNotifierProvider<SearchQueryController, SearchQueryState>((ref) {
  return SearchQueryController(ref.watch(searchRepositoryProvider));
});

class SearchQueryController extends StateNotifier<SearchQueryState> {
  SearchQueryController(this._repository) : super(const SearchQueryState());
  final SearchRepository _repository;

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true, errorMessage: null);
    final result = await _repository.search(query);
    result.when(
      success: (products) => state = state.copyWith(isLoading: false, results: products),
      failure: (e) => state = state.copyWith(isLoading: false, errorMessage: e.message),
    );
  }

  void clear() => state = const SearchQueryState();
}
