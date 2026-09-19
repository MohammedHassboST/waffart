import '../../../core/cache/hive_cache_service.dart';
import '../domain/entities/cart_item.dart';

class OfflineCartService {
  static const String _itemsKey = 'items';
  static const String _pendingOrdersKey = 'pending_orders';

  /// حفظ السلة محلياً
  static Future<void> saveCart(List<CartItem> items) async {
    await HiveCacheService.cart.clear();
    for (var i = 0; i < items.length; i++) {
      await HiveCacheService.cart.put('$i', {
        'id': items[i].id,
        'productId': items[i].productId,
        'vendorId': items[i].vendorId,
        'offerId': items[i].offerId,
        'productName': items[i].productName,
        'vendorName': items[i].vendorName,
        'imageUrl': items[i].imageUrl,
        'quantity': items[i].quantity,
        'unitPrice': items[i].unitPrice,
        'originalPrice': items[i].originalPrice,
      });
    }
    await HiveCacheService.meta.put(_itemsKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// قراءة السلة المحفوظة
  static List<CartItem> loadCart() {
    final list = <CartItem>[];
    for (var i = 0; i < HiveCacheService.cart.length; i++) {
      final data = HiveCacheService.cart.get('$i');
      if (data == null) continue;
      list.add(CartItem(
        id: data['id'] as String,
        productId: data['productId'] as String,
        vendorId: data['vendorId'] as String,
        offerId: data['offerId'] as String?,
        productName: data['productName'] as String,
        vendorName: data['vendorName'] as String,
        imageUrl: data['imageUrl'] as String,
        quantity: data['quantity'] as int,
        unitPrice: (data['unitPrice'] as num).toDouble(),
        originalPrice: (data['originalPrice'] as num?)?.toDouble(),
      ));
    }
    return list;
  }

  /// حفظ طلب معلق (يُنفذ عند عودة الاتصال)
  static Future<void> queueOrder(Map<String, dynamic> order) async {
    final existing = HiveCacheService.meta.get(_pendingOrdersKey, defaultValue: []) as List;
    existing.add({
      ...order,
      'queued_at': DateTime.now().toIso8601String(),
    });
    await HiveCacheService.meta.put(_pendingOrdersKey, existing);
  }

  static List<Map<String, dynamic>> getPendingOrders() {
    final raw = HiveCacheService.meta.get(_pendingOrdersKey, defaultValue: []);
    return List<Map<String, dynamic>>.from(raw as List);
  }

  static Future<void> clearPendingOrders() async {
    await HiveCacheService.meta.delete(_pendingOrdersKey);
  }
}