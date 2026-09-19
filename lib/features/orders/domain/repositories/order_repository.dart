import '../../../cart/domain/entities/cart_item.dart';
import '../entities/order_response.dart';

abstract class OrderRepository {
  Future<OrderResponse> confirmOrder({
    required String customerId,
    required List<CartItem> items,
    required String deliveryAddress,
    String? notes,
  });
}