class CartItem {
  final String id;
  final String productId;
  final String vendorId;
  final String? offerId;
  final String productName;
  final String vendorName;
  final String imageUrl;
  final int quantity;
  final double unitPrice;
  final double? originalPrice;

  const CartItem({
    required this.id,
    required this.productId,
    required this.vendorId,
    this.offerId,
    required this.productName,
    required this.vendorName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    this.originalPrice,
  });

  double get totalPrice => quantity * unitPrice;

  CartItem copyWith({int? quantity}) => CartItem(
    id: id,
    productId: productId,
    vendorId: vendorId,
    offerId: offerId,
    productName: productName,
    vendorName: vendorName,
    imageUrl: imageUrl,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice,
    originalPrice: originalPrice,
  );

  Map<String, dynamic> toRpcJson() => {
    'product_id': productId,
    'offer_id': offerId,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
}