import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../domain/entities/order_response.dart';
import '../../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final SupabaseClient _client;
  OrderRepositoryImpl(this._client);

  @override
  Future<OrderResponse> confirmOrder({
    required String customerId,
    required List<CartItem> items,
    required String deliveryAddress,
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw const ValidationException('السلة فارغة');
    }
    if (deliveryAddress.trim().isEmpty) {
      throw const ValidationException('عنوان التوصيل مطلوب');
    }
    if (notes != null && notes.trim().isEmpty) {
      throw const ValidationException('ملاحظات التوصيل مطلوبة');
    }
    try {
      final response = await _client.rpc('confirm_order_atomic', params: {
        'p_customer_id': customerId,
        'p_cart_items': items.map((e) => e.toRpcJson()).toList(),
        'p_delivery_address': deliveryAddress,
        'p_notes': notes,
      });

      if (response == null) {
        throw const ServerException('فشل تأكيد الطلب');
      }
      return OrderResponse.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}