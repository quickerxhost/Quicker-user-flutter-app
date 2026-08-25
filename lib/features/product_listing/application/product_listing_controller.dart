import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../home/domain/models/product_model.dart';
import '../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository(ref.watch(dioClientProvider)));

enum ListLayout { grid, list }

class ProductListingState {
  final List<ProductModel> products;
  final int page;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isInitialLoading;
  final String? errorMessage;
  final ListLayout layout;
  final ProductSort sort;

  const ProductListingState({
    this.products = const [],
    this.page = 1,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.isInitialLoading = true,
    this.errorMessage,
    this.layout = ListLayout.grid,
    this.sort = ProductSort.relevance,
  });

  ProductListingState copyWith({
    List<ProductModel>? products,
    int? page,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isInitialLoading,
    String? errorMessage,
    ListLayout? layout,
    ProductSort? sort,
  }) {
    return ProductListingState(
      products: products ?? this.products,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      errorMessage: errorMessage,
      layout: layout ?? this.layout,
      sort: sort ?? this.sort,
    );
  }
}

final productListingControllerProvider = StateNotifierProvider.family<ProductListingController, ProductListingState, String?>(
  (ref, categoryId) => ProductListingController(ref.watch(productRepositoryProvider), categoryId),
);

class ProductListingController extends StateNotifier<ProductListingState> {
  ProductListingController(this._repository, this._categoryId) : super(const ProductListingState()) {
    loadFirstPage();
  }

  final ProductRepository _repository;
  final String? _categoryId;

  Future<void> loadFirstPage() async {
    state = state.copyWith(isInitialLoading: true, errorMessage: null, page: 1);
    final result = await _repository.getProducts(categoryId: _categoryId, page: 1, sort: state.sort);
    result.when(
      success: (products) => state = state.copyWith(
        products: products,
        isInitialLoading: false,
        hasMore: products.isNotEmpty,
        page: 1,
      ),
      failure: (e) => state = state.copyWith(isInitialLoading: false, errorMessage: e.message),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;
    final result = await _repository.getProducts(categoryId: _categoryId, page: nextPage, sort: state.sort);
    result.when(
      success: (products) => state = state.copyWith(
        products: [...state.products, ...products],
        isLoadingMore: false,
        hasMore: products.isNotEmpty,
        page: nextPage,
      ),
      failure: (e) => state = state.copyWith(isLoadingMore: false, errorMessage: e.message),
    );
  }

  void toggleLayout() {
    state = state.copyWith(layout: state.layout == ListLayout.grid ? ListLayout.list : ListLayout.grid);
  }

  void changeSort(ProductSort sort) {
    state = state.copyWith(sort: sort);
    loadFirstPage();
  }

  void toggleWishlist(String productId) {
    state = state.copyWith(
      products: state.products.map((p) => p.id == productId ? p.copyWith(isWishlisted: !p.isWishlisted) : p).toList(),
    );
  }
}
