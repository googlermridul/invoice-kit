part of 'recurring_cubit.dart';

class RecurringState extends Equatable {
  const RecurringState({this.loading = false, this.schedules = const [], this.lastGeneratedCount = 0});

  factory RecurringState.initial() => const RecurringState();

  final bool loading;
  final List<RecurringInvoice> schedules;
  final int lastGeneratedCount;

  RecurringState copyWith({bool? loading, List<RecurringInvoice>? schedules, int? lastGeneratedCount}) =>
      RecurringState(
        loading: loading ?? this.loading,
        schedules: schedules ?? this.schedules,
        lastGeneratedCount: lastGeneratedCount ?? this.lastGeneratedCount,
      );

  @override
  List<Object?> get props => [loading, schedules, lastGeneratedCount];
}
