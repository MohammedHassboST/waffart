import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/offer.dart';
import '../repositories/offer_repository.dart';

class GetActiveOffers {
  final OfferRepository repository;
  GetActiveOffers(this.repository);

  Future<Either<Failure, List<Offer>>> call({
    String? categoryId,
    String? vendorId,
    String? search,
    OfferSort sort = OfferSort.newest,
  }) {
    return repository.getActiveOffers(
      categoryId: categoryId,
      vendorId: vendorId,
      search: search,
      sort: sort,
    );
  }
}