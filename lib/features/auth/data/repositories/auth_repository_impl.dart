import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;
  AuthRepositoryImpl(this._supabase);

  @override
  Future<void> sendOtp(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone);
  }

  @override
  Future<AppUser> verifyOtp(String phone, String token) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.sms,
      token: token,
      phone: phone,
    );
    if (response.user == null) {
      throw Exception('فشل التحقق من الرمز');
    }
    // انتظر قليلاً ليكتمل الـ trigger
    await Future.delayed(const Duration(milliseconds: 800));
    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();
    return AppUserModel.fromJson(profile);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      return AppUserModel.fromJson(profile);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Stream<bool> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) => event.session != null);

  @override
  Stream<AppUser?> get userChanges =>
      _supabase.auth.onAuthStateChange.asyncMap((event) async {
        if (event.session == null) return null;
        return await getCurrentUser();
      });
}