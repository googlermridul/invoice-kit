import 'package:equatable/equatable.dart';

/// Subscription billing plans offered by InvoiceKit.
enum SubscriptionPlan {
  monthly,
  yearly;

  int get id => index;
  String get label => switch (this) {
    SubscriptionPlan.monthly => 'Monthly',
    SubscriptionPlan.yearly => 'Yearly',
  };

  static SubscriptionPlan fromId(int id) => SubscriptionPlan.values.firstWhere(
    (p) => p.id == id,
    orElse: () => SubscriptionPlan.monthly,
  );
}

/// Subscription lifecycle.
enum SubscriptionState {
  /// User has never subscribed. Trial may or may not be active.
  none,

  /// Free trial is currently active.
  trialing,

  /// Paid subscription is active and not expired.
  active,

  /// Trial or subscription has expired and not renewed.
  expired,

  /// User cancelled (auto-renew off); still active until period ends.
  cancelled,
}

class SubscriptionStatus extends Equatable {
  const SubscriptionStatus({
    required this.state,
    this.plan,
    this.trialStart,
    this.trialEnd,
    this.currentPeriodEnd,
    this.originalTransactionId,
    this.productId,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final stateName = (json['state'] ?? 'none').toString();
    final state = SubscriptionState.values.firstWhere(
      (s) => s.name == stateName,
      orElse: () => SubscriptionState.none,
    );
    return SubscriptionStatus(
      state: state,
      plan: json['plan'] == null
          ? null
          : SubscriptionPlan.fromId((json['plan'] as num).toInt()),
      trialStart: json['trialStart'] == null
          ? null
          : DateTime.parse(json['trialStart'] as String),
      trialEnd: json['trialEnd'] == null
          ? null
          : DateTime.parse(json['trialEnd'] as String),
      currentPeriodEnd: json['currentPeriodEnd'] == null
          ? null
          : DateTime.parse(json['currentPeriodEnd'] as String),
      originalTransactionId: json['originalTransactionId'] as String?,
      productId: json['productId'] as String?,
    );
  }

  /// Default state: no trial, no subscription.
  factory SubscriptionStatus.initial() =>
      const SubscriptionStatus(state: SubscriptionState.none);

  final SubscriptionState state;
  final SubscriptionPlan? plan;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final DateTime? currentPeriodEnd;
  final String? originalTransactionId;
  final String? productId;

  bool get isTrialing => state == SubscriptionState.trialing;
  bool get isActive =>
      state == SubscriptionState.active || state == SubscriptionState.cancelled;
  bool get isExpired =>
      state == SubscriptionState.expired || state == SubscriptionState.none;

  /// Whether the user currently has access to premium features.
  ///
  /// Implements the contract:
  ///
  ///   hasPremiumAccess = subscriptionActive || freeTrialActive
  ///
  /// `subscriptionActive` covers both paid (`active`) and grace-period
  /// (`cancelled` while still inside the paid window). `freeTrialActive`
  /// covers the `trialing` state while the trial window is still open.
  /// Evaluated against [now] on every call so an expired trial takes
  /// effect on the very next read — the router guard relies on this
  /// rather than on any cached bloc state.
  bool hasAccess(DateTime now) {
    switch (state) {
      case SubscriptionState.trialing:
        return trialEnd != null && trialEnd!.isAfter(now);
      case SubscriptionState.active:
        return currentPeriodEnd == null || currentPeriodEnd!.isAfter(now);
      case SubscriptionState.cancelled:
        return currentPeriodEnd != null && currentPeriodEnd!.isAfter(now);
      case SubscriptionState.none:
      case SubscriptionState.expired:
        return false;
    }
  }

  SubscriptionStatus copyWith({
    SubscriptionState? state,
    SubscriptionPlan? plan,
    DateTime? trialStart,
    DateTime? trialEnd,
    DateTime? currentPeriodEnd,
    String? originalTransactionId,
    String? productId,
  }) {
    return SubscriptionStatus(
      state: state ?? this.state,
      plan: plan ?? this.plan,
      trialStart: trialStart ?? this.trialStart,
      trialEnd: trialEnd ?? this.trialEnd,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      originalTransactionId:
          originalTransactionId ?? this.originalTransactionId,
      productId: productId ?? this.productId,
    );
  }

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'plan': plan?.id,
    'trialStart': trialStart?.toIso8601String(),
    'trialEnd': trialEnd?.toIso8601String(),
    'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
    'originalTransactionId': originalTransactionId,
    'productId': productId,
  };

  @override
  List<Object?> get props => [
    state,
    plan,
    trialStart,
    trialEnd,
    currentPeriodEnd,
    originalTransactionId,
    productId,
  ];
}
