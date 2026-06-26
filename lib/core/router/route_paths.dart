import 'package:invoice_kit/core/router/route_names.dart' show RouteNames;

/// Route paths. Keep [RoutePaths] and [RouteNames] in sync.
class RoutePaths {
  const RoutePaths._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String startTrial = '/start-trial';
  static const String subscription = '/subscription';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String businessProfile = '/business-profile';
  static const String clients = '/clients';
  static const String clientDetail = '/clients/:id';
  static const String clientEdit = '/clients/:id/edit';
  static const String clientNew = '/clients/new';
  static const String invoices = '/invoices';
  static const String invoiceDetail = '/invoices/:id';
  static const String invoiceEdit = '/invoices/:id/edit';
  static const String invoiceNew = '/invoices/new';
  static const String quotes = '/quotes';
  static const String quoteDetail = '/quotes/:id';
  static const String quoteEdit = '/quotes/:id/edit';
  static const String quoteNew = '/quotes/new';
  static const String recurring = '/recurring';
  static const String reports = '/reports';
  static const String fx = '/fx';
  static const String backup = '/backup';
  static const String settings = '/settings';
  static const String home = '/home';
  static const String devices = '/devices';
  static const String trialExpired = '/trial-expired';
  static const String dashboardHomeAlias = 'home';

  static String clientDetailPath(String id) => '/clients/$id';
  static String clientEditPath(String id) => '/clients/$id/edit';
  static String invoiceDetailPath(String id) => '/invoices/$id';
  static String invoiceEditPath(String id) => '/invoices/$id/edit';
  static String quoteDetailPath(String id) => '/quotes/$id';
  static String quoteEditPath(String id) => '/quotes/$id/edit';
}
