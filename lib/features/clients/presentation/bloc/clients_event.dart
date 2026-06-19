part of 'clients_cubit.dart';

abstract class ClientsEvent extends Equatable {
  const ClientsEvent();
  @override
  List<Object?> get props => const [];
}

class ClientsLoadRequested extends ClientsEvent {
  const ClientsLoadRequested();
}

class ClientsSearchChanged extends ClientsEvent {
  const ClientsSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class ClientsUpsertRequested extends ClientsEvent {
  const ClientsUpsertRequested(this.client);
  final Client client;
  @override
  List<Object?> get props => [client];
}

class ClientsDeleteRequested extends ClientsEvent {
  const ClientsDeleteRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
