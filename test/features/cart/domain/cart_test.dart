import 'package:flutter_test/flutter_test.dart';
import 'package:waffart/features/cart/domain/entities/cart_item.dart';

void main() {
  group('CartItem', () {
    test('totalPrice يحسب الكمية × السعر', () {
      final item = CartItem(
        id: '1',
        productId: 'p1',
        vendorId: 'v1',
        productName: 'منتج',
        vendorName: 'مورد',
        imageUrl: '',
        quantity: 5,
        unitPrice: 20,
      );

      expect(item.totalPrice, 100);
    });

    test('copyWith يحتفظ بالحقول الأخرى', () {
      final item = CartItem(
        id: '1',
        productId: 'p1',
        vendorId: 'v1',
        productName: 'منتج',
        vendorName: 'مورد',
        imageUrl: '',
        quantity: 5,
        unitPrice: 20,
      );

      final updated = item.copyWith(quantity: 10);

      expect(updated.quantity, 10);
      expect(updated.productName, item.productName);
      expect(updated.unitPrice, item.unitPrice);
    });
  });
}