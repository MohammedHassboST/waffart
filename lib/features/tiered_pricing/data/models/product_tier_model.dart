import '../../domain/entities/product_tier.dart';

class ProductTierModel extends ProductTier {
  const ProductTierModel({
    required super.id,
    required super.productId,
    required super.minQuantity,
    super.maxQuantity,
    required super.pricePerUnit,
  });

  factory ProductTierModel.fromJson(Map<String, dynamic> json) {
    return ProductTierModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      minQuantity: json['min_quantity'] as int,
      maxQuantity: json['max_quantity'] as int?,
      pricePerUnit: (json['price_per_unit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'min_quantity': minQuantity,
    'max_quantity': maxQuantity,
    'price_per_unit': pricePerUnit,
  };
}