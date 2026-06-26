import 'package:invoice_kit/features/premium/domain/entities/premium_access_decision.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';

/// Single source of truth for whether the user can perform a premium
/// action. Lives in `premium/domain/services` so blocs / cubits / route
/// guards can depend on it without pulling in Dio, Hive or anything
/// presentation-specific.
class PremiumChecker {
  const PremiumChecker();

  /// Evaluate premium access for a given [status] at [now]. The decision
  /// follows the project rule:
  ///
  ///   granted = (active trial && now < trialEnd) ||
  ///             (active paid subscription) ||
  ///             (cancelled but still inside currentPeriodEnd) ||
  ///             (in grace period)
  PremiumAccessDecision evaluate({
    required SubscriptionStatus status,
    required DateTime now,
    required bool isAuthenticated,
  }) {
    switch (status.state) {
      case SubscriptionState.trialing:
        if (status.trialEnd == null) {
          return const PremiumAccessDecision(
            result: PremiumAccessResult.deniedNoTrial,
            reason: 'Trial window not configured.',
          );
        }
        if (status.trialEnd!.isAfter(now)) {
          return PremiumAccessDecision.granted;
        }
        return const PremiumAccessDecision(
          result: PremiumAccessResult.deniedExpiredTrial,
          reason: 'Free trial ended.',
        );
      case SubscriptionState.active:
        if (status.currentPeriodEnd == null ||
            status.currentPeriodEnd!.isAfter(now)) {
          return PremiumAccessDecision.granted;
        }
        return const PremiumAccessDecision(
          result: PremiumAccessResult.deniedExpiredTrial,
          reason: 'Subscription period ended.',
        );
      case SubscriptionState.cancelled:
        if (status.currentPeriodEnd != null &&
            status.currentPeriodEnd!.isAfter(now)) {
          return const PremiumAccessDecision(
            result: PremiumAccessResult.cancelledButActive,
            reason: 'Subscription cancelled but active until period end.',
          );
        }
        return const PremiumAccessDecision(
          result: PremiumAccessResult.deniedExpiredTrial,
        );
      case SubscriptionState.gracePeriod:
        if (status.currentPeriodEnd == null ||
            status.currentPeriodEnd!.isAfter(now)) {
          return const PremiumAccessDecision(
            result: PremiumAccessResult.gracePeriod,
            reason: 'In billing grace period.',
          );
        }
        return const PremiumAccessDecision(
          result: PremiumAccessResult.deniedExpiredTrial,
        );
      case SubscriptionState.none:
      case SubscriptionState.expired:
      case SubscriptionState.pending:
        if (!isAuthenticated) {
          return const PremiumAccessDecision(
            result: PremiumAccessResult.deniedNotAuthenticated,
            reason: 'Please sign in to continue.',
          );
        }
        return const PremiumAccessDecision(
          result: PremiumAccessResult.deniedExpiredTrial,
          reason: 'No active trial or subscription.',
        );
    }
  }
}
