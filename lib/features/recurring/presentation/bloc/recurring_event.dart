part of 'recurring_cubit.dart';

abstract class RecurringEvent extends Equatable {
  const RecurringEvent();
  @override
  List<Object?> get props => const [];
}

class RecurringLoadRequested extends RecurringEvent {
  const RecurringLoadRequested();
}

class RecurringRunDueRequested extends RecurringEvent {
  const RecurringRunDueRequested();
}

class RecurringUpsertRequested extends RecurringEvent {
  const RecurringUpsertRequested(this.schedule);
  final RecurringInvoice schedule;
  @override
  List<Object?> get props => [schedule];
}

class RecurringDeleteRequested extends RecurringEvent {
  const RecurringDeleteRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
