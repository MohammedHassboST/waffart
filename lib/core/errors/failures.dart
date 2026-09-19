abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'خطأ في السيرفر']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'تحقق من الإنترنت']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'خطأ في التخزين المحلي']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'خطأ في المصادقة']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'حدث خطأ غير متوقع']);
}

/// 🆕 نظير ValidationException
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'بيانات غير صحيحة']);
}