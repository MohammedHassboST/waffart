import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

typedef PageFetcher<T> = Future<List<T>> Function(int offset, int limit);

class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  final PageFetcher<T> fetcher;
  static const int pageSize = 20;
  int _currentOffset = 0;
  bool _isFetching = false;

  PaginatedNotifier(this.fetcher) : super(const PaginatedState()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final items = await fetcher(0, pageSize);
      _currentOffset = items.length;
      state = state.copyWith(
        items: items,
        hasMore: items.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(error: e);
    }
  }

  Future<void> loadMore() async {
    if (_isFetching || !state.hasMore) return;
    _isFetching = true;
    state = state.copyWith(isLoadingMore: true);
    try {
      final newItems = await fetcher(_currentOffset, pageSize);
      _currentOffset += newItems.length;
      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoadingMore: false,
        hasMore: newItems.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    _currentOffset = 0;
    state = const PaginatedState();
    await _loadInitial();
  }
}