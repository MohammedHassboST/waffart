import 'package:flutter_test/flutter_test.dart';
import 'package:waffart/features/cart/domain/entities/cart_item.dart';

void main() {
  group('CartItem', () {
    test('totalPrice = qty * unitPrice', () {
      final item = CartItem(
        id: '1', productId: 'p', vendorId: 'v',
        productName: 'n', vendorName: 'vn', imageUrl: '',
        quantity: 5, unitPrice: 20,
      );
      expect(item.totalPrice, 100);
    });
  });
}