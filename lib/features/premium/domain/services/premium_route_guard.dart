import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_access_manager.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_context.dart';

/// Outcomes from a [PremiumRouteGuard.evaluate] call.
enum PremiumRouteDecision {
  allow,
  redirectToAuth,
  redirectToSubscription,
  redirectToDeviceManagement,
}

/// Routes that require premium access. Anything not in this list is
/// freely accessible to authenticated users.
const Set<String> _premiumPaths = {
  RoutePaths.reports,
};

/// Sub-paths of premium routes that require an *editing* premium.
const Set<String> _premiumEditorPaths = {
  RoutePaths.invoiceNew,
  RoutePaths.invoiceEdit,
  RoutePaths.quoteNew,
  RoutePaths.quoteEdit,
};

/// Centralised guard that decides whether the caller should be allowed to
/// proceed. Returns the redirect target when access is denied so the
/// router can perform a single `context.go(...)` from one place.
class PremiumRouteGuard {
  const PremiumRouteGuard(this._manager);

  final PremiumAccessManager _manager;

  /// Convenience check used by inline actions like "Share invoice" or
  /// "Export PDF". Returns null when the call should be allowed; returns
  /// the path to redirect to otherwise.
  String? protect(PremiumContext context, String location) {
    final requiresPremium = _requiresPremium(location);
    if (!requiresPremium) return null;

    final outcome = _manager.resolve(context);
    if (outcome.isGranted) return null;
    return _redirectTarget(outcome.redirect);
  }

  /// Returns the resolved decision for a given location and context.
  PremiumRouteDecision evaluate(PremiumContext context, String location) {
    final requiresPremium = _requiresPremium(location);
    if (!requiresPremium) return PremiumRouteDecision.allow;

    final outcome = _manager.resolve(context);
    if (outcome.isGranted) return PremiumRouteDecision.allow;

    return switch (outcome.redirect) {
      PremiumRedirect.toAuth => PremiumRouteDecision.redirectToAuth,
      PremiumRedirect.toSubscription =>
        PremiumRouteDecision.redirectToSubscription,
      PremiumRedirect.toDeviceManagement =>
        PremiumRouteDecision.redirectToDeviceManagement,
      PremiumRedirect.none => PremiumRouteDecision.allow,
    };
  }

  bool _requiresPremium(String location) {
    if (_premiumPaths.contains(location)) return true;
    for (final p in _premiumEditorPaths) {
      if (location == p) return true;
    }
    return false;
  }

  String _redirectTarget(PremiumRedirect redirect) {
    return switch (redirect) {
      PremiumRedirect.toAuth => RoutePaths.login,
      PremiumRedirect.toSubscription => RoutePaths.subscription,
      PremiumRedirect.toDeviceManagement => RoutePaths.devices,
      PremiumRedirect.none => RoutePaths.dashboard,
    };
  }
}
