import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/offer.dart';

/// 🎛️ ترتيب العروض
enum OfferSort {
  newest,
  endingSoon,
  lowestPrice,
  highestDiscount,
}

abstract class OfferRepository {
  Future<Either<Failure, List<Offer>>> getActiveOffers({
    String? categoryId,
    String? vendorId,
    String? search,
    OfferSort sort,
  });

  Stream<Offer> watchOffer(String offerId);
}