import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/hive_json_store.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';

abstract class ClientRepository {
  Future<List<Client>> all();
  Future<Client?> byId(String id);
  Future<void> save(Client client);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<Client>> search(String query);
  Stream<List<Client>> watchAll();
}

class ClientRepositoryImpl implements ClientRepository {
  ClientRepositoryImpl(this._store);

  final HiveJsonStore<Client> _store;

  static ClientRepository create(HiveStorageService storage) =>
      ClientRepositoryImpl(
        HiveJsonStore<Client>(
          storage: storage,
          boxName: HiveBoxes.clients,
          fromJson: Client.fromJson,
          toJson: (c) => c.toJson(),
        ),
      );

  @override
  Future<List<Client>> all() => _store.all();

  @override
  Future<Client?> byId(String id) => _store.byId(id);

  @override
  Future<void> save(Client client) => _store.save(client, client.id);

  @override
  Future<void> delete(String id) => _store.delete(id);

  @override
  Future<void> clear() => _store.clear();

  @override
  Future<List<Client>> search(String query) async {
    final all = await this.all();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.email ?? '').toLowerCase().contains(q) ||
          (c.company ?? '').toLowerCase().contains(q) ||
          (c.phone ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Stream<List<Client>> watchAll() async* {
    yield await all();
    // Re-emit on every list save by polling. The implementation
    // polls on a heartbeat; consumers that need precise notifications
    // should rely on the BLoC pipeline.
    await for (final _ in Stream<void>.periodic(const Duration(seconds: 5))) {
      yield await all();
    }
  }
}
