import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hive_cache_service.dart';

/// يدير حالة الشبكة والكاش
class CacheManager {
  static const Duration offersTtl = Duration(minutes: 15);
  static const Duration productsTtl = Duration(hours: 2);

  bool hasValidOffers() =>
      HiveCacheService.isValid('offers_', offersTtl);
  bool hasValidProducts() =>
      HiveCacheService.isValid('products_', productsTtl);

  List<Map<String, dynamic>> getCachedOffers() =>
      HiveCacheService.readList(HiveCacheService.offers);

  List<Map<String, dynamic>> getCachedProducts() =>
      HiveCacheService.readList(HiveCacheService.products);
}

final cacheManagerProvider = Provider<CacheManager>((ref) => CacheManager());