part of 'premium_cubit.dart';

enum PremiumStatus { initial, loading, ready }

class PremiumState extends Equatable {
  const PremiumState({
    this.status = PremiumStatus.initial,
    this.decision = const PremiumAccessDecision(
      result: PremiumAccessResult.deniedNoTrial,
    ),
  });

  const PremiumState._()
    : decision = const PremiumAccessDecision(
        result: PremiumAccessResult.deniedNoTrial,
      ),
      status = PremiumStatus.initial;

  factory PremiumState.initial() => const PremiumState._();

  final PremiumStatus status;
  final PremiumAccessDecision decision;

  bool get hasAccess => decision.isGranted;

  PremiumState copyWith({
    PremiumStatus? status,
    PremiumAccessDecision? decision,
  }) {
    return PremiumState(
      status: status ?? this.status,
      decision: decision ?? this.decision,
    );
  }

  @override
  List<Object?> get props => [status, decision];
}
