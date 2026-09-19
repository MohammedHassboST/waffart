import '../entities/product_tier.dart';

abstract class TierRepository {
  Future<List<ProductTier>> getTiersForProduct(String productId);
  Future<ProductTier> addTier({
    required String productId,
    required int minQuantity,
    int? maxQuantity,
    required double pricePerUnit,
  });
  Future<void> updateTier(ProductTier tier);
  Future<void> deleteTier(String tierId);
  Future<double> calculatePrice(String productId, int quantity);
}