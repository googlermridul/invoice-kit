import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';

/// Single source of truth for whether the user can access premium features.
/// Used by feature gates, route guards, and the dashboard paywall card.
class EntitlementService {
  const EntitlementService();

  bool isInTrial(SubscriptionStatus status, DateTime now) {
    if (!status.isTrialing) return false;
    return status.trialEnd != null && status.trialEnd!.isAfter(now);
  }

  /// Days remaining in trial (clamped to >= 0).
  int trialDaysRemaining(SubscriptionStatus status, DateTime now) {
    if (!isInTrial(status, now)) return 0;
    final end = status.trialEnd!;
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final diff = endDay.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Whether the user currently has access — trial OR paid.
  bool hasAccess(SubscriptionStatus status, DateTime now) => status.hasAccess(now);

  /// Whether the user must subscribe to use the app (trial expired or never started
  /// and no active subscription).
  bool isBlocked(SubscriptionStatus status, DateTime now) => !status.hasAccess(now);

  /// Whether the user can start a trial at all. Only true if they've never
  /// had a trial before.
  bool canStartTrial(SubscriptionStatus status) {
    return status.state == SubscriptionState.none && status.trialStart == null;
  }

  /// Build a new trial status starting now.
  SubscriptionStatus startTrial(SubscriptionStatus current, DateTime now) {
    return current.copyWith(
      state: SubscriptionState.trialing,
      trialStart: now,
      trialEnd: now.add(InvoiceConstants.trialDuration),
    );
  }

  /// Activate a paid subscription.
  SubscriptionStatus activate({
    required SubscriptionStatus current,
    required SubscriptionPlan plan,
    required DateTime now,
    DateTime? periodEnd,
  }) {
    return current.copyWith(
      state: SubscriptionState.active,
      plan: plan,
      currentPeriodEnd: periodEnd ?? _defaultPeriodEnd(plan, now),
    );
  }

  /// Mark subscription as expired (e.g. cancelled and period ended).
  SubscriptionStatus expire(SubscriptionStatus current) {
    return current.copyWith(state: SubscriptionState.expired);
  }

  DateTime _defaultPeriodEnd(SubscriptionPlan plan, DateTime now) {
    switch (plan) {
      case SubscriptionPlan.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case SubscriptionPlan.yearly:
        return DateTime(now.year + 1, now.month, now.day);
    }
  }
}
