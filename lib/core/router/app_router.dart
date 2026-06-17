import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/router/route_guards.dart';
import 'package:flutter_boilerplate/core/widgets/error_screen.dart';
import 'package:flutter_boilerplate/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:flutter_boilerplate/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:flutter_boilerplate/features/authentication/presentation/screens/login_screen.dart';
import 'package:flutter_boilerplate/features/authentication/presentation/screens/register_screen.dart';
import 'package:flutter_boilerplate/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_boilerplate/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter_boilerplate/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_boilerplate/features/splash/presentation/screens/splash_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter({required this.authBloc}) {
    _router = GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final auth = authBloc.state;
        return RouteGuards.redirectAfterAuth(context, state, auth);
      },
      routes: [
        GoRoute(path: '/', name: 'splash', builder: (_, _) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(path: '/login', name: 'login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', name: 'register', builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(path: '/home', name: 'home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/settings', name: 'settings', builder: (_, _) => const SettingsScreen()),
      ],
      errorBuilder: (_, state) => ErrorScreen(error: state.error),
    );
  }

  final AuthBloc authBloc;
  late final GoRouter _router;

  GoRouter get router => _router;
}

/// Bridges a [Stream] to [GoRouter]'s `refreshListenable` API.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final dynamic _subscription;

  @override
  void dispose() {
    (_subscription as dynamic).cancel();
    super.dispose();
  }
}
