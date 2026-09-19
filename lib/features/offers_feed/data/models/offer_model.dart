import '../../domain/entities/offer.dart';

class OfferModel {
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
  final int soldQuantity;
  final int remainingQuantity;
  final String saleType;
  final DateTime startAt;
  final DateTime? endAt;
  final bool isActive;

  const OfferModel({
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
    required this.soldQuantity,
    required this.remainingQuantity,
    required this.saleType,
    required this.startAt,
    this.endAt,
    required this.isActive,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    final vendor = json['vendors'] as Map<String, dynamic>?;
    final images = (product?['image_urls'] as List?)?.cast<String>() ?? [];
    return OfferModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      vendorId: json['vendor_id'] as String,
      title: json['title'] as String? ?? '',
      productName: product?['name_ar'] as String? ?? product?['name'] as String? ?? 'صنف',
      vendorName: vendor?['store_name'] as String? ?? 'مورد',
      imageUrl: images.isNotEmpty ? images.first : '',
      originalPrice: (json['original_price'] as num? ?? product?['base_price'] as num? ?? 0).toDouble(),
      offerPrice: (json['offer_price'] as num? ?? 0).toDouble(),
      totalQuantity: json['total_quantity'] as int? ?? 0,
      soldQuantity: json['sold_quantity'] as int? ?? 0,
      remainingQuantity: json['remaining_quantity'] as int? ?? 0,
      saleType: json['sale_type'] as String? ?? 'unit',
      startAt: DateTime.parse(json['start_at'] as String? ?? DateTime.now().toIso8601String()),
      endAt: json['end_at'] != null ? DateTime.parse(json['end_at'] as String) : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Offer toEntity() {
    return Offer(
      id: id,
      productId: productId,
      vendorId: vendorId,
      title: title,
      productName: productName,
      vendorName: vendorName,
      imageUrl: imageUrl,
      originalPrice: originalPrice,
      offerPrice: offerPrice,
      totalQuantity: totalQuantity,
      remainingQuantity: remainingQuantity,
      startAt: startAt,
      endAt: endAt ?? DateTime.now().add(const Duration(days: 7)),
      saleType: saleType,
      isActive: isActive,
      soldQuantity: soldQuantity,
    );
  }
}
