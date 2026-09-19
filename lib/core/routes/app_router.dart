import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/screens/admin_mobile_layout.dart';
import '../../features/admin/presentation/screens/admin_web_layout.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/offers_feed/presentation/screens/offers_feed_screen.dart';
import '../../core/responsive/responsive_helper.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // 🔔 notifier يستمع لتغيّر حالة تسجيل الدخول ويُبلّغ GoRouter
  final notifier = ValueNotifier<bool>(false);
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    notifier.value = next.isLoggedIn;
  });
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/login';
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      // ❌ غير مسجل دخول → وجّهه لـ /login
      if (!isLoggedIn && !isLoggingIn) return '/login';

      // ✅ مسجل دخول وواقف على /login → وجّهه حسب الدور
      if (isLoggedIn && isLoggingIn) {
        final role = authState.user?.role;
        switch (role) {
          case 'admin':
            return '/admin';
          case 'vendor':
          // مؤقتاً: وجّهه لـ /offers لحد ما نبني /vendor
            return '/offers';
          default:
            return '/offers';
        }
      }

      // ✅ مسجل دخول لكن بيحاول يدخل /admin وهو مش admin
      if (isLoggedIn && isAdminRoute && authState.user?.role != 'admin') {
        return '/offers';
      }

      return null;
    },
    routes: [
      // ──────────────────────────────────────────────
      // 🔐 Login
      // ──────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const PhoneLoginScreen(),
      ),

      // ──────────────────────────────────────────────
      // 🛍️ Offers Feed (الافتراضي للعملاء والموردين)
      // ──────────────────────────────────────────────
      GoRoute(
        path: '/offers',
        name: 'offers',
        builder: (context, state) => const OffersFeedScreen(),
      ),

      // ──────────────────────────────────────────────
      // 👑 Admin (mobile + web responsive)
      // ──────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) {
          if (ResponsiveHelper.isDesktop(context)) {
            return const AdminWebLayout();
          }
          return const AdminMobileLayout();
        },
      ),
    ],
  );
});