import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════
// 🔵 Supabase Auth (كود أصلي - محفوظ للرجوع إليه)
// ═══════════════════════════════════════════════════════════════
//
// import '../../../../core/network/supabase_client.dart';
//
// Stream<AuthState> get supabaseAuthStream =>
//     SupabaseClientProvider.client.auth.onAuthStateChange;
//
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// 👤 AppUser
// ═══════════════════════════════════════════════════════════════

class AppUser {
  final String id;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final String? businessName;
  final String? address;
  final String role;

  const AppUser({
    required this.id,
    this.email,
    this.phone,
    this.fullName,
    this.avatarUrl,
    this.businessName,
    this.address,
    this.role = 'customer',
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? avatarUrl,
    String? businessName,
    String? address,
    String? role,
  }) =>
      AppUser(
        id: id ?? this.id,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        fullName: fullName ?? this.fullName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        businessName: businessName ?? this.businessName,
        address: address ?? this.address,
        role: role ?? this.role,
      );
}

// ═══════════════════════════════════════════════════════════════
// 🎛️ AuthState
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
// 🎛️ AuthController
// ═══════════════════════════════════════════════════════════════

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  Future<void> signIn(AppUser user) async {
    state = state.copyWith(isLoading: true, clearError: true);
    state = state.copyWith(user: user, isLoading: false);
    debugPrint('✅ Signed in as ${user.phone ?? user.email} (${user.role})');
  }

  Future<void> signOut() async {
    state = const AuthState();
    debugPrint('👋 Signed out');
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎁 Providers — 🎯 المفتاح: provider واحد فقط!
// ═══════════════════════════════════════════════════════════════

/// ✅ الـ provider الوحيد للـ auth — كل حاجة بتقرأ منه
final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>(
      (ref) => AuthController(),
);

/// ✅ alias بسيط — نفس الـ controller
final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authControllerProvider);
});

/// المستخدم الحالي — AsyncValue (لـ profile_screen)
final currentUserProvider = Provider<AsyncValue<AppUser?>>((ref) {
  final state = ref.watch(authControllerProvider);
  if (state.isLoading) return const AsyncValue.loading();
  if (state.error != null) {
    return AsyncValue.error(state.error!, StackTrace.current);
  }
  return AsyncValue.data(state.user);
});

/// هل مسجل دخول؟
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isLoggedIn;
});

// ═══════════════════════════════════════════════════════════════
// 🎭 Role Selection
// ═══════════════════════════════════════════════════════════════

enum UserRole { customer, vendor, admin }

extension UserRoleX on UserRole {
  String get key => name;

  String get labelAr {
    switch (this) {
      case UserRole.customer:
        return 'عميل';
      case UserRole.vendor:
        return 'مورد';
      case UserRole.admin:
        return 'مدير';
    }
  }

  String get homeRoute {
    switch (this) {
      case UserRole.customer:
        return '/customer';
      case UserRole.vendor:
        return '/vendor';
      case UserRole.admin:
        return '/admin';
    }
  }
}

final selectedRoleProvider = StateProvider<UserRole>(
      (ref) => UserRole.customer,
);