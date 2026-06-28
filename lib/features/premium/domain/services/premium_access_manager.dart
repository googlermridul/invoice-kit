import 'package:invoice_kit/features/premium/domain/entities/premium_access_decision.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_checker.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_context.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';
import 'package:invoice_kit/features/subscription/domain/services/entitlement_service.dart'
    show EntitlementService;

/// Outcomes the [PremiumAccessManager] can hand back to the UI layer.
enum PremiumRedirect {
  /// Caller is allowed to proceed.
  none,

  /// Redirect to the auth / login screen.
  toAuth,

  /// Redirect to the subscription / paywall screen.
  toSubscription,

  /// Redirect to the device management screen because the device cap
  /// was reached.
  toDeviceManagement,
}

class PremiumAccessOutcome {
  const PremiumAccessOutcome({
    required this.decision,
    required this.redirect,
  });

  final PremiumAccessDecision decision;
  final PremiumRedirect redirect;

  bool get isGranted => decision.isGranted && redirect == PremiumRedirect.none;
}

/// Centralised decision authority. Every premium check in the app should
/// go through this class — UI / route guards / cubits should *not* call
/// [EntitlementService] directly for premium gating.
class PremiumAccessManager {
  const PremiumAccessManager(this._checker);

  final PremiumChecker _checker;

  /// Convenience: quick boolean check for non-route UI elements.
  bool hasAccess({
    required SubscriptionStatus status,
    required bool isAuthenticated,
    DateTime? now,
  }) {
    return _checker
        .evaluate(
          status: status,
          now: now ?? DateTime.now(),
          isAuthenticated: isAuthenticated,
        )
        .isGranted;
  }

  /// Route-level check: returns a [PremiumAccessOutcome] that bundles
  /// the decision with the screen the caller should redirect to.
  PremiumAccessOutcome resolve(PremiumContext context) {
    if (context.isAuthenticated && context.deviceCount > context.maxDevices) {
      return const PremiumAccessOutcome(
        decision: PremiumAccessDecision(
          result: PremiumAccessResult.deniedExpiredTrial,
          reason: 'Device limit exceeded.',
        ),
        redirect: PremiumRedirect.toDeviceManagement,
      );
    }

    final decision = _checker.evaluate(
      status: context.status,
      now: context.effectiveNow(),
      isAuthenticated: context.isAuthenticated,
    );

    if (decision.isGranted) {
      return PremiumAccessOutcome(
        decision: decision,
        redirect: PremiumRedirect.none,
      );
    }

    final redirect = switch (decision.result) {
      PremiumAccessResult.deniedNotAuthenticated => PremiumRedirect.toAuth,
      PremiumAccessResult.deniedNoTrial ||
      PremiumAccessResult.deniedExpiredTrial =>
        context.isAuthenticated
            ? PremiumRedirect.toSubscription
            : PremiumRedirect.toAuth,
      PremiumAccessResult.granted ||
      PremiumAccessResult.gracePeriod ||
      PremiumAccessResult.cancelledButActive => PremiumRedirect.none,
    };

    return PremiumAccessOutcome(decision: decision, redirect: redirect);
  }
}
