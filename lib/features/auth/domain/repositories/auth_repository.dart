import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phone);
  Future<AppUser> verifyOtp(String phone, String token);
  Future<AppUser?> getCurrentUser();
  Future<void> signOut();
  Stream<bool> get authStateChanges;
  Stream<AppUser?> get userChanges;
}