import 'package:flutter/widgets.dart';
import 'package:flutter_boilerplate/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';

/// Marker used by [GoRouter] `redirect` to know which routes require auth.
class RouteGuards {
  const RouteGuards._();

  static const List<String> publicRoutes = [
    '/',
    '/onboarding',
    '/login',
    '/register',
    '/forgot-password',
    '/404',
  ];

  static bool requiresAuth(String location) => !publicRoutes.contains(location);

  /// Hook used by [GoRouter.refreshListenable] when auth state changes.
  static String? redirectAfterAuth(BuildContext context, GoRouterState state, AuthState auth) {
    final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    if (auth.isAuthenticated) {
      return loggingIn ? '/home' : null;
    }
    return requiresAuth(state.matchedLocation) ? '/login' : null;
  }
}
