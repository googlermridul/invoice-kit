import 'dart:async';

import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/hive_json_store.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/features/recurring/domain/entities/recurring_invoice.dart';

abstract class RecurringRepository {
  Future<List<RecurringInvoice>> all();
  Future<RecurringInvoice?> byId(String id);
  Future<void> save(RecurringInvoice recurring);
  Future<void> delete(String id);
  Future<void> clear();
  Stream<List<RecurringInvoice>> watchAll();
}

class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl(this._store);

  final HiveJsonStore<RecurringInvoice> _store;

  static RecurringRepository create(HiveStorageService storage) =>
      RecurringRepositoryImpl(
        HiveJsonStore<RecurringInvoice>(
          storage: storage,
          boxName: HiveBoxes.recurring,
          fromJson: RecurringInvoice.fromJson,
          toJson: (r) => r.toJson(),
        ),
      );

  @override
  Future<List<RecurringInvoice>> all() => _store.all();

  @override
  Future<RecurringInvoice?> byId(String id) => _store.byId(id);

  @override
  Future<void> save(RecurringInvoice recurring) => _store.save(recurring, recurring.id);

  @override
  Future<void> delete(String id) => _store.delete(id);

  @override
  Future<void> clear() => _store.clear();

  @override
  Stream<List<RecurringInvoice>> watchAll() async* {
    yield await all();
    await for (final _ in Stream<void>.periodic(const Duration(seconds: 5))) {
      yield await all();
    }
  }
}
