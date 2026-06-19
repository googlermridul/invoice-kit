part of 'clients_cubit.dart';

class ClientsState extends Equatable {
  const ClientsState({
    this.loading = false,
    this.query = '',
    this.clients = const [],
    this.invoiceCountByClient = const {},
    this.quoteCountByClient = const {},
  });

  factory ClientsState.initial() => const ClientsState();

  final bool loading;
  final String query;
  final List<Client> clients;
  final Map<String, int> invoiceCountByClient;
  final Map<String, int> quoteCountByClient;

  ClientsState copyWith({
    bool? loading,
    String? query,
    List<Client>? clients,
    Map<String, int>? invoiceCountByClient,
    Map<String, int>? quoteCountByClient,
  }) => ClientsState(
    loading: loading ?? this.loading,
    query: query ?? this.query,
    clients: clients ?? this.clients,
    invoiceCountByClient: invoiceCountByClient ?? this.invoiceCountByClient,
    quoteCountByClient: quoteCountByClient ?? this.quoteCountByClient,
  );

  @override
  List<Object?> get props => [loading, query, clients, invoiceCountByClient, quoteCountByClient];
}
