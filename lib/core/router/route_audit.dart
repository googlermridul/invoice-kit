import 'package:invoice_kit/core/router/route_names.dart';
import 'package:invoice_kit/core/router/route_paths.dart';

/// Static helpers for verifying that [RoutePaths], [RouteNames] and the
/// actual GoRouter config are kept in sync.
///
/// These functions never spin up a `GoRouter` — they're a pure-data audit
/// used by `test/router/route_audit_test.dart` to catch drift between:
///   * declared constants (RoutePaths / RouteNames)
///   * the routes wired up in `AppRouter`
///   * navigation call sites that hard-code path strings
class RouteAudit {
  const RouteAudit._();

  /// Every path that [AppRouter] declares as a routable location.
  ///
  /// Must be kept in sync with `app_router.dart`. Missing a path here
  /// only means the test won't catch a stale nav-call to it — it never
  /// causes false positives.
  static const Set<String> declaredAbsolutePaths = {
    RoutePaths.splash,
    RoutePaths.onboarding,
    RoutePaths.subscription,
    RoutePaths.login,
    RoutePaths.register,
    RoutePaths.forgotPassword,
    RoutePaths.home,
    RoutePaths.dashboard,
    RoutePaths.businessProfile,
    RoutePaths.clients,
    RoutePaths.invoices,
    RoutePaths.quotes,
    RoutePaths.recurring,
    RoutePaths.reports,
    RoutePaths.fx,
    RoutePaths.backup,
    RoutePaths.settings,
  };

  /// Every named route that [AppRouter] declares.
  ///
  /// Routes that exist purely as redirects (e.g. `/home`) are intentionally
  /// excluded — they have no `name`.
  static const Set<String> declaredRouteNames = {
    RouteNames.splash,
    RouteNames.onboarding,
    RouteNames.subscription,
    RouteNames.login,
    RouteNames.register,
    RouteNames.forgotPassword,
    RouteNames.dashboard,
    RouteNames.home,
    RouteNames.businessProfile,
    RouteNames.clients,
    RouteNames.clientNew,
    RouteNames.clientDetail,
    RouteNames.clientEdit,
    RouteNames.invoices,
    RouteNames.invoiceNew,
    RouteNames.invoiceDetail,
    RouteNames.invoiceEdit,
    RouteNames.quotes,
    RouteNames.quoteNew,
    RouteNames.quoteDetail,
    RouteNames.quoteEdit,
    RouteNames.recurring,
    RouteNames.reports,
    RouteNames.fx,
    RouteNames.backup,
    RouteNames.settings,
  };

  /// Lookup a [RoutePaths] path from a [RouteNames] name. Returns `null`
  /// if the name isn't a recognized top-level route.
  static String? pathForName(String name) {
    switch (name) {
      case RouteNames.splash:
        return RoutePaths.splash;
      case RouteNames.onboarding:
        return RoutePaths.onboarding;
      case RouteNames.subscription:
        return RoutePaths.subscription;
      case RouteNames.login:
        return RoutePaths.login;
      case RouteNames.register:
        return RoutePaths.register;
      case RouteNames.forgotPassword:
        return RoutePaths.forgotPassword;
      case RouteNames.dashboard:
        return RoutePaths.dashboard;
      case RouteNames.businessProfile:
        return RoutePaths.businessProfile;
      case RouteNames.clients:
        return RoutePaths.clients;
      case RouteNames.invoices:
        return RoutePaths.invoices;
      case RouteNames.quotes:
        return RoutePaths.quotes;
      case RouteNames.recurring:
        return RoutePaths.recurring;
      case RouteNames.reports:
        return RoutePaths.reports;
      case RouteNames.fx:
        return RoutePaths.fx;
      case RouteNames.backup:
        return RoutePaths.backup;
      case RouteNames.settings:
        return RoutePaths.settings;
      default:
        return null;
    }
  }
}
