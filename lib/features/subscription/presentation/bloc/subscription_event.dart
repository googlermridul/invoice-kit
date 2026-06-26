part of 'subscription_bloc.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => const [];
}

class SubscriptionStarted extends SubscriptionEvent {
  const SubscriptionStarted();
}

class SubscriptionRefreshed extends SubscriptionEvent {
  const SubscriptionRefreshed();
}

class SubscriptionPlanPurchased extends SubscriptionEvent {
  const SubscriptionPlanPurchased(this.plan);
  final SubscriptionPlan plan;
  @override
  List<Object?> get props => [plan];
}

class SubscriptionRestored extends SubscriptionEvent {
  const SubscriptionRestored();
}

class SubscriptionExpired extends SubscriptionEvent {
  const SubscriptionExpired();
}

/// Fired by the dashboard banner when the user taps "Start trial" so the
/// bloc can persist a freshly started trial.
class SubscriptionTrialStarted extends SubscriptionEvent {
  const SubscriptionTrialStarted(this.status);
  final SubscriptionStatus status;
  @override
  List<Object?> get props => [status];
}

/// Fired when Google Play reports a purchase is pending (e.g. awaiting
/// payment method confirmation). Access is held back until the SDK
/// reports `purchased`.
class SubscriptionPurchasePending extends SubscriptionEvent {
  const SubscriptionPurchasePending({this.productId});
  final String? productId;
  @override
  List<Object?> get props => [productId];
}

/// Fired when the subscription enters the billing grace period. The
/// entitlement remains active so the user is not locked out mid-renewal.
class SubscriptionGracePeriodEntered extends SubscriptionEvent {
  const SubscriptionGracePeriodEntered({this.expiryDate});
  final DateTime? expiryDate;
  @override
  List<Object?> get props => [expiryDate];
}

/// Fired when the user cancels auto-renewal. The current period keeps
/// access; subsequent periods do not.
class SubscriptionCancelled extends SubscriptionEvent {
  const SubscriptionCancelled();
}

/// Fired by the Supabase sync layer after re-fetching the row.
class SubscriptionSyncedFromBackend extends SubscriptionEvent {
  const SubscriptionSyncedFromBackend(this.status);
  final SubscriptionStatus status;
  @override
  List<Object?> get props => [status];
}
