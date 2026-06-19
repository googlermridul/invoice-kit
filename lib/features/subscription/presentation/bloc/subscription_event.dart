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
