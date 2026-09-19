import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cache configuration for providers
class CacheConfig {
  static const Duration shortCache = Duration(minutes: 2);
  static const Duration mediumCache = Duration(minutes: 10);
  static const Duration longCache = Duration(hours: 1);
  static const Duration veryLongCache = Duration(hours: 24);
}

/// مزود مع cache تلقائي
AutoDisposeFutureProvider<T> cacheableProvider<T>({
  required Future<T> Function(Ref) fetcher,
  Duration duration = CacheConfig.mediumCache,
}) {
  return FutureProvider.autoDispose<T>((ref) async {
    final link = ref.keepAlive();
    final timer = Timer(duration, link.close);
    ref.onDispose(timer.cancel);
    return fetcher(ref);
  });
}
