import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import '../auth_notifier.dart';

class OnboardingGuard extends RouteGuard {
  @override
  Future<void> onNavigation(
      NavigationResolver resolver,
      BuildContext context,
      GoRouterState state,
      ) async {
    if (authNotifier.onboardingCompleted) {
      resolver.next();
    } else {
      resolver.redirect('/onboarding');
    }
  }
}