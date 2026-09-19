import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../data/repositories/offer_repository_impl.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';

// 🏭 Repository
final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepositoryImpl(SupabaseClientProvider.client);
});

// 🎛️ Filters
class OfferFilters {
  final String? categoryId;
  final String? vendorId;
  final String? search;
  final OfferSort sort;

  const OfferFilters({
    this.categoryId,
    this.vendorId,
    this.search,
    this.sort = OfferSort.newest,
  });

  OfferFilters copyWith({
    String? categoryId,
    String? vendorId,
    String? search,
    OfferSort? sort,
  }) =>
      OfferFilters(
        categoryId: categoryId ?? this.categoryId,
        vendorId: vendorId ?? this.vendorId,
        search: search ?? this.search,
        sort: sort ?? this.sort,
      );
}

final offerFiltersProvider =
StateProvider<OfferFilters>((ref) => const OfferFilters());

// 📋 Active offers
final activeOffersProvider = FutureProvider<List<Offer>>((ref) async {
  final repo = ref.watch(offerRepositoryProvider);
  final filters = ref.watch(offerFiltersProvider);

  final result = await repo.getActiveOffers(
    categoryId: filters.categoryId,
    vendorId: filters.vendorId,
    search: filters.search,
    sort: filters.sort,
  );

  return result.fold(
        (failure) => throw Exception(failure.message),
        (offers) => offers,
  );
});

// 👁️ Watch single offer
final liveOfferProvider = StreamProvider.family<Offer, String>((ref, id) {
  return ref.watch(offerRepositoryProvider).watchOffer(id);
});

// ═══════════════════════════════════════════════════════
// 📄 Pagination
// ═══════════════════════════════════════════════════════

class PaginatedOffersState {
  final List<Offer> offers;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final Object? error;

  const PaginatedOffersState({
    this.offers = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 0,
    this.error,
  });

  List<Offer> get items => offers;

  PaginatedOffersState copyWith({
    List<Offer>? offers,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    Object? error,
  }) =>
      PaginatedOffersState(
        offers: offers ?? this.offers,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: error,
      );
}

class PaginatedOffersNotifier extends AsyncNotifier<PaginatedOffersState> {
  static const _pageSize = 20;

  @override
  Future<PaginatedOffersState> build() async {
    final filters = ref.watch(offerFiltersProvider);
    return _loadPage(page: 0, filters: filters, current: null);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final filters = ref.read(offerFiltersProvider);
    final next = await _loadPage(
      page: current.page + 1,
      filters: filters,
      current: current,
    );
    state = AsyncData(next);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<PaginatedOffersState> _loadPage({
    required int page,
    required OfferFilters filters,
    required PaginatedOffersState? current,
  }) async {
    final repo = ref.read(offerRepositoryProvider);
    final result = await repo.getActiveOffers(
      categoryId: filters.categoryId,
      vendorId: filters.vendorId,
      search: filters.search,
      sort: filters.sort,
    );

    return result.fold(
          (failure) => PaginatedOffersState(
        offers: current?.offers ?? const <Offer>[],
        page: current?.page ?? 0,
        hasMore: false,
        isLoadingMore: false,
        error: failure.message,
      ),
          (newOffers) {
        final existing = current?.offers ?? const <Offer>[];
        final combined = <Offer>[...existing, ...newOffers];
        return PaginatedOffersState(
          offers: combined,
          page: page,
          hasMore: newOffers.length >= _pageSize,
          isLoadingMore: false,
        );
      },
    );
  }
}

final paginatedOffersProvider =
AsyncNotifierProvider<PaginatedOffersNotifier, PaginatedOffersState>(
  PaginatedOffersNotifier.new,
);