class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'خطأ في السيرفر']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'تحقق من الإنترنت']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'خطأ في التخزين المحلي']);
}

/// ⚠️ اسمها مختلف عن supabase's AuthException لتفادي التعارض
class AppAuthException implements Exception {
  final String message;
  const AppAuthException([this.message = 'خطأ في المصادقة']);
}

/// 🆕 للتحقق من صحة البيانات (validation)
class ValidationException implements Exception {
  final String message;
  const ValidationException([this.message = 'بيانات غير صحيحة']);
}