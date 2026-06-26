import 'package:equatable/equatable.dart';

/// Local-only trial state. Persisted to Hive and shared with the
/// `features/subscription` bloc so the rest of the app keeps using its
/// existing `SubscriptionStatus` contract without modification.
class TrialState extends Equatable {
  const TrialState({
    required this.startedAt,
    required this.endsAt,
    required this.expired,
  });

  factory TrialState.fromJson(Map<String, dynamic> json) => TrialState(
    startedAt: DateTime.parse(json['startedAt'] as String),
    endsAt: DateTime.parse(json['endsAt'] as String),
    expired: json['expired'] == true,
  );

  /// Build a [TrialState] starting now with the default 7-day window.
  factory TrialState.fresh(DateTime now) => TrialState(
    startedAt: now,
    endsAt: now.add(const Duration(days: 7)),
    expired: false,
  );

  /// Returns true while the trial window is still open.
  bool isActive(DateTime now) => !expired && endsAt.isAfter(now);

  /// Whole days remaining in the trial (clamped to 0).
  int daysRemaining(DateTime now) {
    if (!isActive(now)) return 0;
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(endsAt.year, endsAt.month, endsAt.day);
    final diff = endDay.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Marks the trial as expired without changing dates. Used when a
  /// user explicitly cancels / leaves the trial early.
  TrialState markExpired() => TrialState(
    startedAt: startedAt,
    endsAt: endsAt,
    expired: true,
  );

  /// Persistable JSON representation.
  Map<String, dynamic> toJson() => {
    'startedAt': startedAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'expired': expired,
  };

  final DateTime startedAt;
  final DateTime endsAt;
  final bool expired;

  @override
  List<Object?> get props => [startedAt, endsAt, expired];
}
