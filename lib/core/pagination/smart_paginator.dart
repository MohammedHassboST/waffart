import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageResult<T> {
  final List<T> items;
  final bool hasMore;
  final int total;
  const PageResult({required this.items, required this.hasMore, this.total = 0});
}

typedef SmartFetcher<T> = Future<PageResult<T>> Function(int page, int pageSize);

class SmartPaginator<T> extends StateNotifier<PaginatedState<T>> {
  final SmartFetcher<T> fetcher;
  final int pageSize;

  static const int _defaultPageSize = 20;
  int _page = 0;
  bool _isLoading = false;

  SmartPaginator(this.fetcher, {this.pageSize = _defaultPageSize})
      : super(const PaginatedState());

  Future<void> loadInitial() async {
    if (_isLoading) return;
    _isLoading = true;
    _page = 0;
    state = const PaginatedState(items: [], isLoadingMore: false);
    try {
      final result = await fetcher(0, pageSize);
      state = PaginatedState(
        items: result.items,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = PaginatedState(error: e);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !state.hasMore) return;
    _isLoading = true;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await fetcher(_page + 1, pageSize);
      _page++;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        isLoadingMore: false,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    } finally {
      _isLoading = false;
    }
  }
}

class PaginatedState<T> {
  final List<T> items;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  const PaginatedState({
    this.items = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
  }) =>
      PaginatedState<T>(
        items: items ?? this.items,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}