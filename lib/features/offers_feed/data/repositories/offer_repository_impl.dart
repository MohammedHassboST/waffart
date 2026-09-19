import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/error_mapper.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';
import '../models/offer_model.dart';

class OfferRepositoryImpl implements OfferRepository {
  final SupabaseClient _client;

  OfferRepositoryImpl(this._client);

  static const _table = 'offers';

  @override
  Future<Either<Failure, List<Offer>>> getActiveOffers({
    String? categoryId,
    String? vendorId,
    String? search,
    OfferSort sort = OfferSort.newest,
  }) async {
    try {
      var query = _client
          .from(_table)
          .select(
        '*, products!inner(name, image_urls, category_id), '
            'vendors(store_name)',
      )
          .eq('is_active', true)
          .gt('remaining_quantity', 0);

      if (vendorId != null) query = query.eq('vendor_id', vendorId);
      if (categoryId != null) {
        query = query.eq('products.category_id', categoryId);
      }
      if (search != null && search.trim().isNotEmpty) {
        final s = search.replaceAll(',', ' ').trim();
        if (s.isNotEmpty) {
          query = query.or(
            'products.name.ilike.%$s%,'
                'vendors.store_name.ilike.%$s%,'
                'title.ilike.%$s%',
          );
        }
      }

      final PostgrestTransformBuilder<PostgrestList> ordered = switch (sort) {
        OfferSort.newest => query.order('created_at', ascending: false),
        OfferSort.endingSoon =>
            query.order('end_at', ascending: true, nullsFirst: false),
        OfferSort.lowestPrice =>
            query.order('offer_price', ascending: true),
        OfferSort.highestDiscount =>
            query.order('original_price', ascending: false),
      };

      final response = await ordered;

      final offers = (response as List)
          .map((json) => OfferModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();

      return Right(offers);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<Offer> watchOffer(String offerId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', offerId)
        .map((data) {
      if (data.isEmpty) {
        throw const ServerException('العرض غير موجود');
      }
      return OfferModel.fromJson(data.first).toEntity();
    });
  }
}