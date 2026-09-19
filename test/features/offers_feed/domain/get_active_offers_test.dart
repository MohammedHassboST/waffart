import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waffart/features/offers_feed/domain/entities/offer.dart';
import 'package:waffart/features/offers_feed/domain/repositories/offer_repository.dart';
import 'package:waffart/features/offers_feed/domain/usecases/get_active_offers.dart';

class MockOfferRepository extends Mock implements OfferRepository {}

void main() {
  late GetActiveOffers usecase;
  late MockOfferRepository mockRepo;

  setUp(() {
    mockRepo = MockOfferRepository();
    usecase = GetActiveOffers(mockRepo);
  });

  group('GetActiveOffers', () {
    test('يعيد قائمة العروض النشطة عند النجاح', () async {
      final offers = [
        Offer(
          id: '1',
          productId: 'p1',
          vendorId: 'v1',
          title: 'عرض تجريبي',
          productName: 'منتج',
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
        ),
      ];

      when(() => mockRepo.getActiveOffers(
        categoryId: any(named: 'categoryId'),
        vendorId: any(named: 'vendorId'),
        search: any(named: 'search'),
        sort: any(named: 'sort'),
      )).thenAnswer((_) async => Right(offers));

      final result = await usecase();

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be right'),
        (r) {
          expect(r.length, 1);
          expect(r.first.id, '1');
        },
      );
      
      verify(() => mockRepo.getActiveOffers(
        categoryId: null,
        vendorId: null,
        search: null,
        sort: OfferSort.newest,
      )).called(1);
    });

    test('يعيد قائمة فارغة إذا لم توجد عروض', () async {
      when(() => mockRepo.getActiveOffers(
        categoryId: any(named: 'categoryId'),
        vendorId: any(named: 'vendorId'),
        search: any(named: 'search'),
        sort: any(named: 'sort'),
      )).thenAnswer((_) async => const Right([]));

      final result = await usecase();
      expect(result.getOrElse(() => []), isEmpty);
    });

    test('ينقل الفلاتر إلى المستودع', () async {
      when(() => mockRepo.getActiveOffers(
        categoryId: 'cat1',
        vendorId: 'v1',
        search: 'طماطم',
        sort: OfferSort.lowestPrice,
      )).thenAnswer((_) async => const Right([]));

      await usecase(
        categoryId: 'cat1',
        vendorId: 'v1',
        search: 'طماطم',
        sort: OfferSort.lowestPrice,
      );

      verify(() => mockRepo.getActiveOffers(
        categoryId: 'cat1',
        vendorId: 'v1',
        search: 'طماطم',
        sort: OfferSort.lowestPrice,
      )).called(1);
    });
  });
}
