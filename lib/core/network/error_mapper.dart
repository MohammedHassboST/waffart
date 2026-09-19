import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../errors/exceptions.dart';
import '../errors/failures.dart';

Failure mapExceptionToFailure(Object e) {
  if (e is ValidationException) return ValidationFailure(e.message);
  if (e is ServerException) return ServerFailure(e.message);
  if (e is NetworkException) return NetworkFailure(e.message);
  if (e is CacheException) return CacheFailure(e.message);
  if (e is AppAuthException) return AuthFailure(e.message);
  if (e is PostgrestException) return ServerFailure(e.message);
  if (e is SocketException) return const NetworkFailure();
  return const UnknownFailure();
}