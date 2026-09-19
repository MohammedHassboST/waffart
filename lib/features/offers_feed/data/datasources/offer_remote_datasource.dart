// features/offers_feed/data/datasources/offer_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/offer_model.dart';

class OfferRemoteDataSource {
  late final SupabaseClient _client;

  Stream<List<OfferModel>> watchActiveOffers() {
    return _client
        .from('offers')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => OfferModel.fromJson(json)).toList());
  }

  // الاستماع لتحديثات كمية عرض معين
  Stream<OfferModel> watchOffer(String offerId) {
    return _client
        .from('offers')
        .stream(primaryKey: ['id'])
        .eq('id', offerId)
        .map((data) => OfferModel.fromJson(data.first))
        .distinct();
  }
}