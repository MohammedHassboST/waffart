import 'package:hive_flutter/hive_flutter.dart';

class HiveCacheService {
  static const String _productsBox = 'products_cache';
  static const String _offersBox = 'offers_cache';
  static const String _cartBox = 'cart_cache';
  static const String _userBox = 'user_cache';
  static const String _metaBox = 'meta_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(_productsBox),
      Hive.openBox<Map>(_offersBox),
      Hive.openBox<Map>(_cartBox),
      Hive.openBox<Map>(_userBox),
      Hive.openBox<dynamic>(_metaBox),
    ]);
  }

  static Box<Map> get products => Hive.box<Map>(_productsBox);
  static Box<Map> get offers => Hive.box<Map>(_offersBox);
  static Box<Map> get cart => Hive.box<Map>(_cartBox);
  static Box<Map> get user => Hive.box<Map>(_userBox);
  static Box get meta => Hive.box(_metaBox);

  /// حفظ قائمة مع الطابع الزمني
  static Future<void> cacheList<T extends Map>(
      Box<Map> box,
      List<T> items,
      String keyPrefix,
      ) async {
    await box.clear();
    for (var i = 0; i < items.length; i++) {
      await box.put('$keyPrefix$i', items[i]);
    }
    await meta.put(
      '${keyPrefix}timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// قراءة القائمة المخزنة
  static List<Map<String, dynamic>> readList(Box<Map> box) {
    return box.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// التحقق من صلاحية الـ cache
  static bool isValid(String keyPrefix, Duration maxAge) {
    final ts = meta.get('${keyPrefix}timestamp') as int?;
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age < maxAge.inMilliseconds;
  }

  /// مسح الكاش بالكامل
  static Future<void> clearAll() async {
    await Future.wait([
      products.clear(),
      offers.clear(),
      user.clear(),
      meta.clear(),
    ]);
  }

  /// حجم الكاش بالميجابايت
  static double getCacheSizeMB() {
    int total = 0;
    total += products.length * 2048; // تقريبي
    total += offers.length * 2048;
    return total / (1024 * 1024);
  }
}