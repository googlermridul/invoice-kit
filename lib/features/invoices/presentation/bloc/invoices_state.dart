part of 'invoices_cubit.dart';

class InvoicesState extends Equatable {
  const InvoicesState({
    this.loading = false,
    this.invoices = const [],
    this.defaultCurrency = 'USD',
    this.error,
  });

  factory InvoicesState.initial() => const InvoicesState();

  final bool loading;
  final List<Invoice> invoices;
  final String defaultCurrency;
  final String? error;

  InvoicesState copyWith({
    bool? loading,
    List<Invoice>? invoices,
    String? defaultCurrency,
    String? error,
    bool clearError = false,
  }) => InvoicesState(
    loading: loading ?? this.loading,
    invoices: invoices ?? this.invoices,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [loading, invoices, defaultCurrency, error];
}
