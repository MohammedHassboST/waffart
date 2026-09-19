class Offer {
  final String id;
  final String productId;
  final String vendorId;
  final String title;
  final String productName;
  final String vendorName;
  final String imageUrl;
  final double originalPrice;
  final double offerPrice;
  final int totalQuantity;
  final int remainingQuantity;
  final DateTime startAt;
  final DateTime endAt;
  final String saleType;
  final bool isActive;
  final int soldQuantity;

  const Offer({
    required this.id,
    required this.productId,
    required this.vendorId,
    required this.title,
    required this.productName,
    required this.vendorName,
    required this.imageUrl,
    required this.originalPrice,
    required this.offerPrice,
    required this.totalQuantity,
    required this.remainingQuantity,
    required this.startAt,
    required this.endAt,
    this.saleType = 'unit',
    this.isActive = true,
    this.soldQuantity = 0,
  });

  // 🧮 الحسابات
  double get discountPercent =>
      originalPrice > 0
          ? ((originalPrice - offerPrice) / originalPrice) * 100
          : 0;

  double get progress =>
      totalQuantity > 0 ? soldQuantity / totalQuantity : 0;

  bool get isExhausted => remainingQuantity <= 0;

  Offer copyWith({
    String? id,
    String? productId,
    String? vendorId,
    String? title,
    String? productName,
    String? vendorName,
    String? imageUrl,
    double? originalPrice,
    double? offerPrice,
    int? totalQuantity,
    int? remainingQuantity,
    DateTime? startAt,
    DateTime? endAt,
    String? saleType,
    bool? isActive,
    int? soldQuantity,
  }) {
    return Offer(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      vendorId: vendorId ?? this.vendorId,
      title: title ?? this.title,
      productName: productName ?? this.productName,
      vendorName: vendorName ?? this.vendorName,
      imageUrl: imageUrl ?? this.imageUrl,
      originalPrice: originalPrice ?? this.originalPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      saleType: saleType ?? this.saleType,
      isActive: isActive ?? this.isActive,
      soldQuantity: soldQuantity ?? this.soldQuantity,
    );
  }
}
