import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';

// ═══════════════════════════════════════════════════════════════
// 🔵 Supabase Auth (كود أصلي - محفوظ للرجوع إليه)
// ═══════════════════════════════════════════════════════════════
//
// Stream<AuthState> get supabaseAuthStream =>
//     SupabaseClientProvider.client.auth.onAuthStateChange;
//
// User? get supabaseCurrentUser =>
//     SupabaseClientProvider.client.auth.currentUser;
//
// ═══════════════════════════════════════════════════════════════

/// 👤 نموذج المستخدم (يُستخدم في كل مكان)
class AppUser {
  final String id;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final String role; // 'customer' | 'vendor' | 'admin'

  const AppUser({
    required this.id,
    this.email,
    this.phone,
    this.fullName,
    this.avatarUrl,
    this.role = 'customer',
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? avatarUrl,
    String? role,
  }) =>
      AppUser(
        id: id ?? this.id,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role ?? this.role,
      );
}

// ═══════════════════════════════════════════════════════════════
// 🎛️ Auth State (بيحمل المستخدم الحالي أو null)
// ═══════════════════════════════════════════════════════════════

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ═══════════════════════════════════════════════════════════════
// 🎛️ Auth Controller (يدير تسجيل الدخول/الخروج)
// ═══════════════════════════════════════════════════════════════

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  /// 🔐 تسجيل دخول (بعد نجاح OTP)
  Future<void> signIn(AppUser user) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // ═══════════════════════════════════════════════════════
    // 🔵 Supabase: (لو المستخدم اتأكد من OTP الحقيقي، فهو مسجل دخول تلقائيًا)
    // ═══════════════════════════════════════════════════════
    // final supabaseUser = SupabaseClientProvider.client.auth.currentUser;
    // if (supabaseUser != null) {
    //   user = AppUser(
    //     id: supabaseUser.id,
    //     phone: supabaseUser.phone,
    //     email: supabaseUser.email,
    //     role: supabaseUser.userMetadata?['role'] ?? 'customer',
    //   );
    // }
    // ═══════════════════════════════════════════════════════

    state = state.copyWith(user: user, isLoading: false);
    debugPrint('✅ Signed in as ${user.phone ?? user.email}');
  }

  /// 🚪 تسجيل خروج
  Future<void> signOut() async {
    // ═══════════════════════════════════════════════════════
    // 🔵 Supabase:
    // await SupabaseClientProvider.client.auth.signOut();
    // ═══════════════════════════════════════════════════════

    state = const AuthState();
    debugPrint('👋 Signed out');
  }

  /// 🧹 مسح الخطأ
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎁 Providers
// ═══════════════════════════════════════════════════════════════

/// الحالة الكاملة للمصادقة
final authStateProvider =
StateNotifierProvider<AuthController, AuthState>(
      (ref) => AuthController(),
);

/// المتحكم في المصادقة (للـ logout وغيرها)
final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>(
      (ref) => AuthController(),
);

/// المستخدم الحالي (null لو مش مسجل)
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).user;
});

/// هل مسجل دخول؟
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoggedIn;
});