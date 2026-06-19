import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/router/app_router_guard.dart';
import 'package:invoice_kit/core/router/route_names.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/widgets/error_screen.dart';
import 'package:invoice_kit/features/backup/presentation/screens/backup_screen.dart';
import 'package:invoice_kit/features/business_profile/presentation/screens/business_profile_screen.dart';
import 'package:invoice_kit/features/clients/presentation/screens/client_detail_screen.dart';
import 'package:invoice_kit/features/clients/presentation/screens/client_edit_screen.dart';
import 'package:invoice_kit/features/clients/presentation/screens/clients_screen.dart';
import 'package:invoice_kit/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:invoice_kit/features/fx/presentation/screens/fx_screen.dart';
import 'package:invoice_kit/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:invoice_kit/features/invoices/presentation/screens/invoice_edit_screen.dart';
import 'package:invoice_kit/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:invoice_kit/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:invoice_kit/features/quotes/presentation/screens/quote_detail_screen.dart';
import 'package:invoice_kit/features/quotes/presentation/screens/quote_edit_screen.dart';
import 'package:invoice_kit/features/quotes/presentation/screens/quotes_screen.dart';
import 'package:invoice_kit/features/recurring/presentation/screens/recurring_screen.dart';
import 'package:invoice_kit/features/reports/presentation/screens/reports_screen.dart';
import 'package:invoice_kit/features/settings/presentation/screens/settings_screen.dart';
import 'package:invoice_kit/features/splash/presentation/screens/splash_screen.dart';
import 'package:invoice_kit/features/subscription/presentation/screens/subscription_screen.dart';

class AppRouter {
  AppRouter({required this.guard}) {
    _router = GoRouter(
      initialLocation: RoutePaths.splash,
      debugLogDiagnostics: kDebugMode,
      refreshListenable: GoRouterRefreshStream(guard.subscriptionBloc.stream),
      redirect: guard.redirect,
      routes: [
        GoRoute(
          path: RoutePaths.splash,
          name: RouteNames.splash,
          builder: (_, _) => const SplashScreen(),
        ),
        GoRoute(
          path: RoutePaths.onboarding,
          name: RouteNames.onboarding,
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: RoutePaths.subscription,
          name: RouteNames.subscription,
          builder: (_, _) => const SubscriptionScreen(),
        ),
        GoRoute(
          path: RoutePaths.dashboard,
          name: RouteNames.dashboard,
          builder: (_, _) => const DashboardScreen(),
        ),
        GoRoute(
          path: RoutePaths.businessProfile,
          name: RouteNames.businessProfile,
          builder: (_, _) => const BusinessProfileScreen(),
        ),
        GoRoute(
          path: RoutePaths.clients,
          name: RouteNames.clients,
          builder: (_, _) => const ClientsScreen(),
          routes: [
            GoRoute(
              path: 'new',
              name: RouteNames.clientNew,
              builder: (_, _) => const ClientEditScreen(),
            ),
            GoRoute(
              path: ':id',
              name: RouteNames.clientDetail,
              builder: (_, state) => ClientDetailScreen(clientId: state.pathParameters['id']!),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: RouteNames.clientEdit,
                  builder: (_, state) => ClientEditScreen(clientId: state.pathParameters['id']),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.invoices,
          name: RouteNames.invoices,
          builder: (_, _) => const InvoicesScreen(),
          routes: [
            GoRoute(
              path: 'new',
              name: RouteNames.invoiceNew,
              builder: (_, _) => const InvoiceEditScreen(),
            ),
            GoRoute(
              path: ':id',
              name: RouteNames.invoiceDetail,
              builder: (_, state) => InvoiceDetailScreen(invoiceId: state.pathParameters['id']!),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: RouteNames.invoiceEdit,
                  builder: (_, state) => InvoiceEditScreen(invoiceId: state.pathParameters['id']),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.quotes,
          name: RouteNames.quotes,
          builder: (_, _) => const QuotesScreen(),
          routes: [
            GoRoute(
              path: 'new',
              name: RouteNames.quoteNew,
              builder: (_, _) => const QuoteEditScreen(),
            ),
            GoRoute(
              path: ':id',
              name: RouteNames.quoteDetail,
              builder: (_, state) => QuoteDetailScreen(quoteId: state.pathParameters['id']!),
              routes: [
                GoRoute(
                  path: 'edit',
                  name: RouteNames.quoteEdit,
                  builder: (_, state) => QuoteEditScreen(quoteId: state.pathParameters['id']),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.recurring,
          name: RouteNames.recurring,
          builder: (_, _) => const RecurringScreen(),
        ),
        GoRoute(
          path: RoutePaths.reports,
          name: RouteNames.reports,
          builder: (_, _) => const ReportsScreen(),
        ),
        GoRoute(
          path: RoutePaths.fx,
          name: RouteNames.fx,
          builder: (_, _) => const FxScreen(),
        ),
        GoRoute(
          path: RoutePaths.backup,
          name: RouteNames.backup,
          builder: (_, _) => const BackupScreen(),
        ),
        GoRoute(
          path: RoutePaths.settings,
          name: RouteNames.settings,
          builder: (_, _) => const SettingsScreen(),
        ),
      ],
      errorBuilder: (_, state) => ErrorScreen(error: state.error),
    );
  }

  final AppRouterGuard guard;
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
