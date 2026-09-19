import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import '../auth_notifier.dart';

class RoleGuard extends RouteGuard {
  final List<String> requiredRoles;
  final String fallbackRoute;

  RoleGuard(this.requiredRoles, {this.fallbackRoute = '/home'});

  @override
  Future<void> onNavigation(
      NavigationResolver resolver,
      BuildContext context,
      GoRouterState state,
      ) async {
    if (requiredRoles.contains(authNotifier.role)) {
      resolver.next();
    } else {
      resolver.redirect(fallbackRoute);
    }
  }
}