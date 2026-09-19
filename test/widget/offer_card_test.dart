import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waffart/features/offers_feed/domain/entities/offer.dart';
import 'package:waffart/features/offers_feed/presentation/widgets/offer_card.dart';

void main() {
  final testOffer = Offer(
    id: '1',
    productId: 'p1',
    vendorId: 'v1',
    title: 'عرض',
    productName: 'طماطم',
    vendorName: 'مورد',
    imageUrl: '',
    originalPrice: 100,
    offerPrice: 80,
    totalQuantity: 100,
    soldQuantity: 30,
    remainingQuantity: 70,
    saleType: 'unit',
    startAt: DateTime.now(),
    endAt: DateTime.now().add(const Duration(days: 7)),
    isActive: true,
  );

  testWidgets('OfferCard يعرض بيانات العرض', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: OfferCard(offer: testOffer, onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.text('طماطم'), findsOneWidget);
    expect(find.text('مورد'), findsOneWidget);
    expect(find.textContaining('70'), findsOneWidget);
    expect(find.textContaining('100'), findsOneWidget);
  });

  testWidgets('OfferCard يستدعي onTap عند الضغط', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: OfferCard(
              offer: testOffer,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(OfferCard));
    expect(tapped, true);
  });

  testWidgets('يعرض شريط تقدم صحيح', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: OfferCard(offer: testOffer, onTap: () {}),
          ),
        ),
      ),
    );

    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 0.3); // 30/100
  });
}
