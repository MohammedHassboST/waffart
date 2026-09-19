import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/offer.dart';
import '../../data/models/offer_model.dart';

/// يدير قناة Realtime لتحديث العروض تلقائياً
class RealtimeOffersNotifier extends StateNotifier<List<Offer>> {
  RealtimeOffersNotifier() : super([]) {
    _subscribe();
  }

  final _client = SupabaseClientProvider.client;
  RealtimeChannel? _channel;

  void _subscribe() {
    _channel = _client.channel('public:offers')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'offers',
        callback: (payload) {
          final updated = OfferModel.fromJson(payload.newRecord).toEntity();
          state = state.map((o) => o.id == updated.id ? updated : o).toList();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'offers',
        callback: (_) {
          // أعد جلب العروض
          refetch();
        },
      )
      ..subscribe();
  }

  Future<void> refetch() async {
    final res = await _client
        .from('offers')
        .select('*, products(name, image_urls), vendors(store_name)')
        .eq('is_active', true)
        .order('created_at', ascending: false);
    state = (res as List)
        .map((e) => OfferModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final realtimeOffersProvider =
StateNotifierProvider<RealtimeOffersNotifier, List<Offer>>(
      (ref) => RealtimeOffersNotifier(),
);
