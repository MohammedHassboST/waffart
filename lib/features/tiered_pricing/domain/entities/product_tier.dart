class ProductTier {
  final String id;
  final String productId;
  final int minQuantity;
  final int? maxQuantity;
  final double pricePerUnit;

  const ProductTier({
    required this.id,
    required this.productId,
    required this.minQuantity,
    this.maxQuantity,
    required this.pricePerUnit,
  });

  String get rangeLabel {
    if (maxQuantity == null) return '$minQuantity+';
    if (minQuantity == maxQuantity) return '$minQuantity';
    return '$minQuantity - $maxQuantity';
  }

  bool matchesQuantity(int qty) {
    if (qty < minQuantity) return false;
    if (maxQuantity != null && qty > maxQuantity!) return false;
    return true;
  }
}