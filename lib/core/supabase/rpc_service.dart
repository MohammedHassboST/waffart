import 'package:supabase_flutter/supabase_flutter.dart';

class RpcService {
  final SupabaseClient _client;
  RpcService(this._client);

  Future<Map<String, dynamic>> confirmOrder({
    required String customerId,
    required List<Map<String, dynamic>> items,
    required String address,
    String? notes,
  }) async {
    return await _client.rpc('confirm_order_atomic', params: {
      'p_customer_id': customerId,
      'p_cart_items': items,
      'p_delivery_address': address,
      'p_notes': notes,
    }) as Map<String, dynamic>;
  }

  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    final res = await _client.rpc('cancel_order_atomic', params: {
      'p_order_id': orderId,
      'p_reason': reason,
    });
    return res['success'] == true;
  }

  Future<Map<String, dynamic>> addProductWithStock({
    required String vendorId,
    String? categoryId,
    required String name,
    String? description,
    required List<String> imageUrls,
    required String saleType,
    required double basePrice,
    required String unitLabel,
    required int initialStock,
  }) async {
    return await _client.rpc('add_product_with_stock', params: {
      'p_vendor_id': vendorId,
      'p_category_id': categoryId,
      'p_name': name,
      'p_description': description,
      'p_image_urls': imageUrls,
      'p_sale_type': saleType,
      'p_base_price': basePrice,
      'p_unit_label': unitLabel,
      'p_initial_stock': initialStock,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> restockProduct(
      String productId,
      int quantity, {
        String? notes,
      }) async {
    return await _client.rpc('restock_product_atomic', params: {
      'p_product_id': productId,
      'p_quantity': quantity,
      'p_notes': notes,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createOffer({
    required String productId,
    required String title,
    required double offerPrice,
    required int totalQuantity,
    required String saleType,
    DateTime? endAt,
  }) async {
    return await _client.rpc('create_offer_atomic', params: {
      'p_product_id': productId,
      'p_title': title,
      'p_offer_price': offerPrice,
      'p_total_quantity': totalQuantity,
      'p_sale_type': saleType,
      'p_end_at': endAt?.toIso8601String(),
    }) as Map<String, dynamic>;
  }
}