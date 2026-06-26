part of 'trial_cubit.dart';

class TrialCubitState extends Equatable {
  const TrialCubitState({
    this.loading = false,
    this.trial,
    this.active = false,
  });

  const TrialCubitState._() : active = false, trial = null, loading = false;

  factory TrialCubitState.initial() => const TrialCubitState._();

  final bool loading;
  final TrialState? trial;
  final bool active;

  int daysRemaining(DateTime now) => trial?.daysRemaining(now) ?? 0;

  TrialCubitState copyWith({bool? loading, TrialState? trial, bool? active}) {
    return TrialCubitState(
      loading: loading ?? this.loading,
      trial: trial ?? this.trial,
      active: active ?? this.active,
    );
  }

  @override
  List<Object?> get props => [loading, trial, active];
}
