import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/clients/data/repositories/client_repository.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_kit/features/quotes/data/repositories/quote_repository.dart';
import 'package:invoice_kit/shared/helpers/id_generator.dart';

part 'clients_event.dart';
part 'clients_state.dart';

class ClientsCubit extends Cubit<ClientsState> {
  ClientsCubit({
    required this.clientRepo,
    required this.invoiceRepo,
    required this.quoteRepo,
  }) : super(ClientsState.initial());

  final ClientRepository clientRepo;
  final InvoiceRepository invoiceRepo;
  final QuoteRepository quoteRepo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final clients = await clientRepo.all();
      final invoices = await invoiceRepo.all();
      final quotes = await quoteRepo.all();
      emit(
        state.copyWith(
          loading: false,
          clients: clients,
          invoiceCountByClient: _countByKey(invoices, (i) => i.clientId),
          quoteCountByClient: _countByKey(quotes, (q) => q.clientId),
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> search(String query) async {
    emit(state.copyWith(loading: true, query: query, clearError: true));
    try {
      final clients = await clientRepo.search(query);
      final invoices = await invoiceRepo.all();
      final quotes = await quoteRepo.all();
      emit(
        state.copyWith(
          loading: false,
          clients: clients,
          invoiceCountByClient: _countByKey(invoices, (i) => i.clientId),
          quoteCountByClient: _countByKey(quotes, (q) => q.clientId),
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> upsert(Client client) async {
    final existing = client.id.isEmpty
        ? Client(
            id: IdGenerator.create('cli'),
            name: client.name,
            email: client.email,
            phone: client.phone,
            address: client.address,
            company: client.company,
            notes: client.notes,
            createdAt: DateTime.now(),
          )
        : client;
    await clientRepo.save(existing);
    await load();
  }

  Future<void> remove(String id) async {
    emit(state.copyWith(clearError: true));
    try {
      await clientRepo.delete(id);
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Map<String, int> _countByKey<T>(List<T> items, String Function(T) key) {
    final map = <String, int>{};
    for (final item in items) {
      final k = key(item);
      map.update(k, (v) => v + 1, ifAbsent: () => 1);
    }
    return map;
  }
}
