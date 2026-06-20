part of 'quotes_cubit.dart';

class QuotesState extends Equatable {
  const QuotesState({
    this.loading = false,
    this.quotes = const [],
    this.defaultCurrency = 'USD',
    this.error,
  });

  factory QuotesState.initial() => const QuotesState();

  final bool loading;
  final List<Quote> quotes;
  final String defaultCurrency;
  final String? error;

  QuotesState copyWith({
    bool? loading,
    List<Quote>? quotes,
    String? defaultCurrency,
    String? error,
    bool clearError = false,
  }) => QuotesState(
    loading: loading ?? this.loading,
    quotes: quotes ?? this.quotes,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [loading, quotes, defaultCurrency, error];
}
