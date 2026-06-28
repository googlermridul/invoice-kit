import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/router/app_router_guard.dart';
import 'package:invoice_kit/core/router/route_names.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/widgets/app_shell.dart';
import 'package:invoice_kit/core/widgets/error_screen.dart';
import 'package:invoice_kit/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:invoice_kit/features/authentication/presentation/screens/login_screen.dart';
import 'package:invoice_kit/features/authentication/presentation/screens/register_screen.dart';
import 'package:invoice_kit/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:invoice_kit/features/backup/presentation/screens/backup_screen.dart';
import 'package:invoice_kit/features/business_profile/presentation/bloc/business_profile_cubit.dart';
import 'package:invoice_kit/features/business_profile/presentation/screens/business_profile_screen.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/clients/presentation/screens/client_detail_screen.dart';
import 'package:invoice_kit/features/clients/presentation/screens/client_edit_screen.dart';
import 'package:invoice_kit/features/clients/presentation/screens/clients_screen.dart';
import 'package:invoice_kit/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:invoice_kit/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:invoice_kit/features/devices/presentation/screens/devices_screen.dart';
import 'package:invoice_kit/features/fx/presentation/bloc/fx_cubit.dart';
import 'package:invoice_kit/features/fx/presentation/screens/fx_screen.dart';
import 'package:invoice_kit/features/invoices/presentation/bloc/invoices_cubit.dart';
import 'package:invoice_kit/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:invoice_kit/features/invoices/presentation/screens/invoice_edit_screen.dart';
import 'package:invoice_kit/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:invoice_kit/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:invoice_kit/features/onboarding/presentation/screens/intro_screen.dart';
import 'package:invoice_kit/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:invoice_kit/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:invoice_kit/features/quotes/presentation/bloc/quotes_cubit.dart';
import 'package:invoice_kit/features/quotes/presentation/screens/quote_detail_screen.dart';
import 'package:invoice_kit/features/quotes/presentation/screens/quote_edit_screen.dart';
import 'package:invoice_kit/features/quotes/presentation/screens/quotes_screen.dart';
import 'package:invoice_kit/features/recurring/presentation/bloc/recurring_cubit.dart';
import 'package:invoice_kit/features/recurring/presentation/screens/recurring_screen.dart';
import 'package:invoice_kit/features/reports/presentation/screens/reports_screen.dart';
import 'package:invoice_kit/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:invoice_kit/features/settings/presentation/screens/settings_screen.dart';
import 'package:invoice_kit/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:invoice_kit/features/splash/presentation/screens/splash_screen.dart';
import 'package:invoice_kit/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:invoice_kit/features/trial/presentation/screens/trial_expired_screen.dart';

class AppRouter {
  AppRouter({required this.guard}) {
    final authBloc = guard.authBloc;
    final subscriptionStream = guard.subscriptionBloc.stream;
    final authStream = authBloc?.stream;
    final refreshListenable = authStream == null
        ? GoRouterRefreshStream(subscriptionStream)
        : _MergedRefreshListenable([
            GoRouterRefreshStream(subscriptionStream),
            GoRouterRefreshStream(authStream),
          ]);
    _router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: RoutePaths.splash,
      debugLogDiagnostics: kDebugMode,
      refreshListenable: refreshListenable,
      redirect: guard.redirect,
      routes: [
        // ── Public / onboarding / auth flows ──────────────────────────────
        // These never show the bottom navigation bar.
        GoRoute(
          path: RoutePaths.splash,
          name: RouteNames.splash,
          builder: (_, _) => BlocProvider(
            create: (_) => sl<SplashBloc>(),
            child: const SplashScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.onboarding,
          name: RouteNames.onboarding,
          builder: (_, _) => BlocProvider(
            create: (_) => sl<OnboardingBloc>(),
            child: const OnboardingScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.onboardingIntro,
          name: RouteNames.onboardingIntro,
          builder: (_, _) => const IntroScreen(),
        ),
        GoRoute(
          path: RoutePaths.onboardingWelcome,
          name: RouteNames.onboardingWelcome,
          builder: (_, _) => const WelcomeScreen(),
        ),
        GoRoute(
          path: RoutePaths.subscription,
          name: RouteNames.subscription,
          builder: (_, _) => const SubscriptionScreen(),
        ),
        GoRoute(
          path: RoutePaths.devices,
          name: RouteNames.devices,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => const DevicesScreen(),
        ),
        GoRoute(
          path: RoutePaths.trialExpired,
          name: RouteNames.trialExpired,
          builder: (_, _) => const TrialExpiredScreen(),
        ),
        GoRoute(
          path: RoutePaths.login,
          name: RouteNames.login,
          builder: (_, _) => const LoginScreen(),
        ),
        GoRoute(
          path: RoutePaths.register,
          name: RouteNames.register,
          builder: (_, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: RoutePaths.forgotPassword,
          name: RouteNames.forgotPassword,
          builder: (_, _) => const ForgotPasswordScreen(),
        ),

        // External `/home` deep links / stale callers — redirect into the
        // dashboard branch.
        GoRoute(
          path: RoutePaths.home,
          redirect: (_, _) => RoutePaths.dashboard,
        ),

        // ── Bottom-nav shell: Dashboard / Invoices / Clients / Quotes / Settings ──
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShellScaffold(navigationShell: navigationShell),
          branches: [
            // Branch 0 — Home / Dashboard
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.dashboard,
                  name: RouteNames.dashboard,
                  builder: (_, _) => BlocProvider(
                    create: (_) => sl<DashboardCubit>(),
                    child: const DashboardScreen(),
                  ),
                  routes: [
                    // Preserve `/dashboard/home` as a redirect target.
                    GoRoute(
                      path: RoutePaths.dashboardHomeAlias,
                      name: RouteNames.home,
                      redirect: (_, _) => RoutePaths.dashboard,
                    ),
                  ],
                ),
              ],
            ),

            // Branch 1 — Invoices
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.invoices,
                  name: RouteNames.invoices,
                  builder: (_, _) => MultiBlocProvider(
                    providers: [
                      BlocProvider<InvoicesCubit>(
                        create: (_) => sl<InvoicesCubit>(),
                      ),
                      BlocProvider<ClientsCubit>(
                        create: (_) => sl<ClientsCubit>(),
                      ),
                    ],
                    child: const InvoicesScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: RouteNames.invoiceNew,
                      builder: (_, _) => MultiBlocProvider(
                        providers: [
                          BlocProvider<InvoicesCubit>(
                            create: (_) => sl<InvoicesCubit>(),
                          ),
                          BlocProvider<ClientsCubit>(
                            create: (_) => sl<ClientsCubit>(),
                          ),
                        ],
                        child: const InvoiceEditScreen(),
                      ),
                    ),
                    GoRoute(
                      path: ':id',
                      name: RouteNames.invoiceDetail,
                      builder: (_, state) => MultiBlocProvider(
                        providers: [
                          BlocProvider<InvoicesCubit>(
                            create: (_) => sl<InvoicesCubit>(),
                          ),
                          BlocProvider<ClientsCubit>(
                            create: (_) => sl<ClientsCubit>(),
                          ),
                        ],
                        child: InvoiceDetailScreen(
                          invoiceId: state.pathParameters['id']!,
                        ),
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          name: RouteNames.invoiceEdit,
                          builder: (_, state) => MultiBlocProvider(
                            providers: [
                              BlocProvider<InvoicesCubit>(
                                create: (_) => sl<InvoicesCubit>(),
                              ),
                              BlocProvider<ClientsCubit>(
                                create: (_) => sl<ClientsCubit>(),
                              ),
                            ],
                            child: InvoiceEditScreen(
                              invoiceId: state.pathParameters['id'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Branch 2 — Clients
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.clients,
                  name: RouteNames.clients,
                  builder: (_, _) => BlocProvider(
                    create: (_) => sl<ClientsCubit>(),
                    child: const ClientsScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: RouteNames.clientNew,
                      builder: (_, _) => BlocProvider(
                        create: (_) => sl<ClientsCubit>(),
                        child: const ClientEditScreen(),
                      ),
                    ),
                    GoRoute(
                      path: ':id',
                      name: RouteNames.clientDetail,
                      builder: (_, state) => BlocProvider(
                        create: (_) => sl<ClientsCubit>(),
                        child: ClientDetailScreen(
                          clientId: state.pathParameters['id']!,
                        ),
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          name: RouteNames.clientEdit,
                          builder: (_, state) => BlocProvider(
                            create: (_) => sl<ClientsCubit>(),
                            child: ClientEditScreen(
                              clientId: state.pathParameters['id'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Branch 3 — Quotes
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.quotes,
                  name: RouteNames.quotes,
                  builder: (_, _) => MultiBlocProvider(
                    providers: [
                      BlocProvider<QuotesCubit>(
                        create: (_) => sl<QuotesCubit>(),
                      ),
                      BlocProvider<ClientsCubit>(
                        create: (_) => sl<ClientsCubit>(),
                      ),
                    ],
                    child: const QuotesScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'new',
                      name: RouteNames.quoteNew,
                      builder: (_, _) => MultiBlocProvider(
                        providers: [
                          BlocProvider<QuotesCubit>(
                            create: (_) => sl<QuotesCubit>(),
                          ),
                          BlocProvider<ClientsCubit>(
                            create: (_) => sl<ClientsCubit>(),
                          ),
                        ],
                        child: const QuoteEditScreen(),
                      ),
                    ),
                    GoRoute(
                      path: ':id',
                      name: RouteNames.quoteDetail,
                      builder: (_, state) => MultiBlocProvider(
                        providers: [
                          BlocProvider<QuotesCubit>(
                            create: (_) => sl<QuotesCubit>(),
                          ),
                          BlocProvider<ClientsCubit>(
                            create: (_) => sl<ClientsCubit>(),
                          ),
                        ],
                        child: QuoteDetailScreen(
                          quoteId: state.pathParameters['id']!,
                        ),
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          name: RouteNames.quoteEdit,
                          builder: (_, state) => MultiBlocProvider(
                            providers: [
                              BlocProvider<QuotesCubit>(
                                create: (_) => sl<QuotesCubit>(),
                              ),
                              BlocProvider<ClientsCubit>(
                                create: (_) => sl<ClientsCubit>(),
                              ),
                            ],
                            child: QuoteEditScreen(
                              quoteId: state.pathParameters['id'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Branch 4 — Settings
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RoutePaths.settings,
                  name: RouteNames.settings,
                  builder: (_, _) => BlocProvider(
                    create: (_) => sl<SettingsCubit>(),
                    child: const SettingsScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Push-only screens that sit on top of the shell ───────────────
        // These never show the bottom navigation bar — they're either
        // modal flows, detail screens, or settings sub-pages reached
        // via explicit `context.push` calls from a tab.
        GoRoute(
          path: RoutePaths.businessProfile,
          name: RouteNames.businessProfile,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => BlocProvider(
            create: (_) => sl<BusinessProfileCubit>(),
            child: const BusinessProfileScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.reports,
          name: RouteNames.reports,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => BlocProvider(
            create: (_) => sl<DashboardCubit>(),
            child: const ReportsScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.recurring,
          name: RouteNames.recurring,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<RecurringCubit>(create: (_) => sl<RecurringCubit>()),
              BlocProvider<ClientsCubit>(create: (_) => sl<ClientsCubit>()),
            ],
            child: const RecurringScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.fx,
          name: RouteNames.fx,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => BlocProvider(
            create: (_) => sl<FxCubit>(),
            child: const FxScreen(),
          ),
        ),
        GoRoute(
          path: RoutePaths.backup,
          name: RouteNames.backup,
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => BlocProvider(
            create: (_) => sl<BackupCubit>(),
            child: const BackupScreen(),
          ),
        ),
      ],
      errorBuilder: (_, state) => ErrorScreen(error: state.error),
    );
  }

  final AppRouterGuard guard;
  late final GoRouter _router;

  GoRouter get router => _router;
}

/// Root navigator key — used by routes that should sit above the
/// [StatefulShellRoute] (modal flows, push-only detail screens).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

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

/// Composes multiple [ChangeNotifier]s into a single [Listenable] so
/// GoRouter re-evaluates redirects when *any* of them notify.
class _MergedRefreshListenable extends ChangeNotifier {
  _MergedRefreshListenable(List<Listenable> children) {
    for (final c in children) {
      c.addListener(_onAnyChanged);
    }
    _children = children;
  }

  late final List<Listenable> _children;

  void _onAnyChanged() => notifyListeners();

  @override
  void dispose() {
    for (final c in _children) {
      c.removeListener(_onAnyChanged);
    }
    super.dispose();
  }
}
