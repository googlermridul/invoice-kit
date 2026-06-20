part of 'fx_cubit.dart';

class FxState extends Equatable {
  const FxState({
    this.loading = false,
    this.refreshing = false,
    this.rates = const [],
    this.base = 'USD',
    this.lastUpdated,
    this.error,
  });

  factory FxState.initial() => const FxState();

  final bool loading;
  final bool refreshing;
  final List<FxRate> rates;
  final String base;
  final DateTime? lastUpdated;
  final String? error;

  FxState copyWith({
    bool? loading,
    bool? refreshing,
    List<FxRate>? rates,
    String? base,
    DateTime? lastUpdated,
    String? error,
    bool clearError = false,
    bool clearLastUpdated = false,
  }) => FxState(
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    rates: rates ?? this.rates,
    base: base ?? this.base,
    lastUpdated: clearLastUpdated ? null : (lastUpdated ?? this.lastUpdated),
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [
    loading,
    refreshing,
    rates,
    base,
    lastUpdated,
    error,
  ];
}
