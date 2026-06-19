import 'dart:async';

import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/hive_json_store.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';

abstract class InvoiceRepository {
  Future<List<Invoice>> all();
  Future<Invoice?> byId(String id);
  Future<void> save(Invoice invoice);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<Invoice>> forClient(String clientId);
  Stream<List<Invoice>> watchAll();
}

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl(this._store);

  final HiveJsonStore<Invoice> _store;

  static InvoiceRepository create(HiveStorageService storage) => InvoiceRepositoryImpl(
        HiveJsonStore<Invoice>(
          storage: storage,
          boxName: HiveBoxes.invoices,
          fromJson: Invoice.fromJson,
          toJson: (i) => i.toJson(),
        ),
      );

  @override
  Future<List<Invoice>> all() => _store.all();

  @override
  Future<Invoice?> byId(String id) => _store.byId(id);

  @override
  Future<void> save(Invoice invoice) => _store.save(invoice, invoice.id);

  @override
  Future<void> delete(String id) => _store.delete(id);

  @override
  Future<void> clear() => _store.clear();

  @override
  Future<List<Invoice>> forClient(String clientId) async {
    final all = await this.all();
    return all.where((i) => i.clientId == clientId).toList();
  }

  @override
  Stream<List<Invoice>> watchAll() async* {
    yield await all();
    await for (final _ in Stream<void>.periodic(const Duration(seconds: 5))) {
      yield await all();
    }
  }
}
