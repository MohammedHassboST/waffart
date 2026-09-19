import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/offers_provider.dart';
import '../widgets/offer_card.dart';

class OffersFeedScreen extends ConsumerStatefulWidget {
  const OffersFeedScreen({super.key});

  @override
  ConsumerState<OffersFeedScreen> createState() => _OffersFeedScreenState();
}

class _OffersFeedScreenState extends ConsumerState<OffersFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    // 📥 لما المستخدم يوصل لـ 80% من القائمة → حمّل المزيد
    if (current >= maxScroll * 0.8) {
      ref.read(paginatedOffersProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(paginatedOffersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('العروض')),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (state) {
          final items = state.offers;
          final isLoadingMore = state.isLoadingMore;
          final hasMore = state.hasMore;

          if (items.isEmpty) {
            return const Center(child: Text('لا توجد عروض'));
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(paginatedOffersProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: items.length + (hasMore || isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  // 🌀 مؤشر التحميل في نهاية القائمة
                  return isLoadingMore
                      ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : const SizedBox.shrink();
                }

                final offer = items[index];
                return OfferCard(
                  offer: offer,
                  onTap: () {
                    // TODO: انتقل لصفحة تفاصيل العرض
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}