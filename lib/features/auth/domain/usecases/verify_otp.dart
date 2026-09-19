import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class VerifyOtp {
  final AuthRepository repository;
  VerifyOtp(this.repository);
  Future<AppUser> call(String phone, String token) =>
      repository.verifyOtp(phone, token);
}