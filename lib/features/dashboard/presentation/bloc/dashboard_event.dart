part of 'dashboard_cubit.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => const [];
}

class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}
