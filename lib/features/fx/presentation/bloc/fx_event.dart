part of 'fx_cubit.dart';

abstract class FxEvent extends Equatable {
  const FxEvent();
  @override
  List<Object?> get props => const [];
}

class FxLoadRequested extends FxEvent {
  const FxLoadRequested();
}

class FxRefreshRequested extends FxEvent {
  const FxRefreshRequested({this.base = 'USD'});
  final String base;
  @override
  List<Object?> get props => [base];
}
