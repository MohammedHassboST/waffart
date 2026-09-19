import 'package:flutter_test/flutter_test.dart';
import 'package:waffart/features/offers_feed/domain/entities/offer.dart';

void main() {
  group('Offer Entity', () {
    test('progress should be 0.5 when half remaining', () {
      final offer = Offer(
        id: '1',
        productId: 'p',
        vendorId: 'v',
        title: 't',
        productName: 'n',
        vendorName: 'vn',
        imageUrl: '',
        originalPrice: 100,
        offerPrice: 80,
        totalQuantity: 100,
        soldQuantity: 50,
        remainingQuantity: 50,
        saleType: 'unit',
        startAt: DateTime.now(),
        endAt: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
      );
      expect(offer.progress, 0.5);
      expect(offer.isExhausted, false);
      expect(offer.discountPercent, 20);
    });

    test('isExhausted should be true when remaining is 0', () {
      final offer = Offer(
        id: '1', productId: 'p', vendorId: 'v', title: 't',
        productName: 'n', vendorName: 'vn', imageUrl: '',
        originalPrice: 100, offerPrice: 80,
        totalQuantity: 100, soldQuantity: 100, remainingQuantity: 0,
        saleType: 'unit', startAt: DateTime.now(), 
        endAt: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
      );
      expect(offer.isExhausted, true);
    });
  });
}
