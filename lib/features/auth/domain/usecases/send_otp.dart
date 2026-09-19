import '../repositories/auth_repository.dart';

class SendOtp {
  final AuthRepository repository;
  SendOtp(this.repository);
  Future<void> call(String phone) => repository.sendOtp(phone);
}