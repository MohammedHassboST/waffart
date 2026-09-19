import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_tier.dart';
import '../../domain/repositories/tier_repository.dart';
import '../models/product_tier_model.dart';

class TierRepositoryImpl implements TierRepository {
  final SupabaseClient _client;
  TierRepositoryImpl(this._client);

  @override
  Future<List<ProductTier>> getTiersForProduct(String productId) async {
    final res = await _client
        .from('product_tiers')
        .select()
        .eq('product_id', productId)
        .order('min_quantity', ascending: true);

    return (res as List)
        .map((e) => ProductTierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProductTier> addTier({
    required String productId,
    required int minQuantity,
    int? maxQuantity,
    required double pricePerUnit,
  }) async {
    final res = await _client
        .from('product_tiers')
        .insert({
      'product_id': productId,
      'min_quantity': minQuantity,
      'max_quantity': maxQuantity,
      'price_per_unit': pricePerUnit,
    })
        .select()
        .single();
    return ProductTierModel.fromJson(res);
  }

  @override
  Future<void> updateTier(ProductTier tier) async {
    await _client.from('product_tiers').update({
      'min_quantity': tier.minQuantity,
      'max_quantity': tier.maxQuantity,
      'price_per_unit': tier.pricePerUnit,
    }).eq('id', tier.id);
  }

  @override
  Future<void> deleteTier(String tierId) async {
    await _client.from('product_tiers').delete().eq('id', tierId);
  }

  @override
  Future<double> calculatePrice(String productId, int quantity) async {
    final res = await _client.rpc('get_tiered_price', params: {
      'p_product_id': productId,
      'p_quantity': quantity,
    });
    return (res as num).toDouble();
  }
}