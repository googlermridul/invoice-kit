import 'package:equatable/equatable.dart';

/// Result of a single premium-access evaluation. Distinct from the boolean
/// answer so callers can show specific upgrade CTAs / paywalls.
enum PremiumAccessResult {
  granted,

  /// Trial expired and no paid subscription.
  deniedExpiredTrial,

  /// Never had a trial, never subscribed.
  deniedNoTrial,

  /// Logged-out user without an active trial.
  deniedNotAuthenticated,

  /// Active subscription is in the grace period.
  gracePeriod,

  /// Subscription is still active but flagged as cancelled by the user —
  /// access continues until `currentPeriodEnd`.
  cancelledButActive,
}

class PremiumAccessDecision extends Equatable {
  const PremiumAccessDecision({required this.result, this.reason});

  final PremiumAccessResult result;

  /// Optional message for the UI to display.
  final String? reason;

  bool get isGranted =>
      result == PremiumAccessResult.granted ||
      result == PremiumAccessResult.gracePeriod ||
      result == PremiumAccessResult.cancelledButActive;

  bool get isDenied => !isGranted;

  static const granted = PremiumAccessDecision(
    result: PremiumAccessResult.granted,
  );

  @override
  List<Object?> get props => [result, reason];
}
