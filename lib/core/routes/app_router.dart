import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_main_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/customer/presentation/screens/customer_main_screen.dart';
import '../../features/vendor/presentation/screens/vendor_main_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);

  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    authNotifier.value = next.isLoggedIn;
  });

  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,

    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.isLoggedIn;
      final user = authState.user;
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) {
        return _homeForRole(user?.role);
      }

      // 🛡️ حماية المسارات حسب الدور
      if (isLoggedIn && user != null) {
        if (location.startsWith('/admin') && user.role != 'admin') {
          return _homeForRole(user.role);
        }
        if (location.startsWith('/vendor') && user.role != 'vendor') {
          return _homeForRole(user.role);
        }
        if (location.startsWith('/customer') && user.role != 'customer') {
          return _homeForRole(user.role);
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const PhoneLoginScreen(),
      ),

      // 🛒 عميل
      GoRoute(
        path: '/customer',
        name: 'customer',
        builder: (context, state) => const CustomerMainScreen(),
      ),

      // 🏪 مورد
      GoRoute(
        path: '/vendor',
        name: 'vendor',
        builder: (context, state) => const VendorMainScreen(),
      ),

      // 👑 مدير
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminMainScreen(),
      ),
    ],
  );
});

String _homeForRole(String? role) {
  switch (role) {
    case 'admin':
      return '/admin';
    case 'vendor':
      return '/vendor';
    default:
      return '/customer';
  }
}