part of 'subscription_bloc.dart';

enum SubscriptionStatusX { initial, loading, ready, refreshing, purchasing, restoring }

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.status = SubscriptionStatusX.initial,
    SubscriptionStatus? subscriptionStatus,
    this.hasAccess = false,
    this.trialDaysRemaining = 0,
    this.message,
  }) : _status = subscriptionStatus;

  factory SubscriptionState.initial() => const SubscriptionState();

  final SubscriptionStatusX status;
  final SubscriptionStatus? _status;
  final bool hasAccess;
  final int trialDaysRemaining;
  final String? message;

  SubscriptionStatus get currentStatus => _status ?? SubscriptionStatus.initial();

  bool get isTrialing => currentStatus.isTrialing;
  bool get isActive => currentStatus.isActive;
  bool get isExpired => currentStatus.isExpired;

  SubscriptionState copyWith({
    SubscriptionStatusX? status,
    SubscriptionStatus? subscriptionStatus,
    bool? hasAccess,
    int? trialDaysRemaining,
    String? message,
    bool clearMessage = false,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      subscriptionStatus: subscriptionStatus ?? _status,
      hasAccess: hasAccess ?? this.hasAccess,
      trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, _status, hasAccess, trialDaysRemaining, message];
}
