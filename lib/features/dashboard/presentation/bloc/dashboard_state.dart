part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.loading = false,
    this.error,
    this.summary,
    this.recentInvoices = const [],
    this.recentClients = const [],
    this.recentQuotes = const [],
    this.clientsById = const {},
  });

  factory DashboardState.initial() => const DashboardState();

  final bool loading;
  final String? error;
  final RevenueSummary? summary;
  final List<Invoice> recentInvoices;
  final List<Client> recentClients;
  final List<Quote> recentQuotes;
  final Map<String, Client> clientsById;

  DashboardState copyWith({
    bool? loading,
    String? error,
    RevenueSummary? summary,
    List<Invoice>? recentInvoices,
    List<Client>? recentClients,
    List<Quote>? recentQuotes,
    Map<String, Client>? clientsById,
    bool clearError = false,
  }) => DashboardState(
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    summary: summary ?? this.summary,
    recentInvoices: recentInvoices ?? this.recentInvoices,
    recentClients: recentClients ?? this.recentClients,
    recentQuotes: recentQuotes ?? this.recentQuotes,
    clientsById: clientsById ?? this.clientsById,
  );

  @override
  List<Object?> get props => [
    loading,
    error,
    summary,
    recentInvoices,
    recentClients,
    recentQuotes,
    clientsById,
  ];
}
