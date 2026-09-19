import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../data/repositories/tier_repository_impl.dart';
import '../../domain/entities/product_tier.dart';
import '../../domain/repositories/tier_repository.dart';

final tierRepositoryProvider = Provider<TierRepository>((ref) {
  return TierRepositoryImpl(SupabaseClientProvider.client);
});

final productTiersProvider =
FutureProvider.family<List<ProductTier>, String>((ref, productId) {
  return ref.watch(tierRepositoryProvider).getTiersForProduct(productId);
});

// حساب السعر بناءً على الكمية (يُستخدم في السلة)
final priceCalculatorProvider =
Provider((ref) => (String productId, int quantity) async {
  return ref
      .read(tierRepositoryProvider)
      .calculatePrice(productId, quantity);
});