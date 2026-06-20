import 'dart:async';

import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/hive_json_store.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';

abstract class QuoteRepository {
  Future<List<Quote>> all();
  Future<Quote?> byId(String id);
  Future<void> save(Quote quote);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<Quote>> forClient(String clientId);
  Stream<List<Quote>> watchAll();
}

class QuoteRepositoryImpl implements QuoteRepository {
  QuoteRepositoryImpl(this._store);

  final HiveJsonStore<Quote> _store;

  static QuoteRepository create(HiveStorageService storage) =>
      QuoteRepositoryImpl(
        HiveJsonStore<Quote>(
          storage: storage,
          boxName: HiveBoxes.quotes,
          fromJson: Quote.fromJson,
          toJson: (q) => q.toJson(),
        ),
      );

  @override
  Future<List<Quote>> all() => _store.all();

  @override
  Future<Quote?> byId(String id) => _store.byId(id);

  @override
  Future<void> save(Quote quote) => _store.save(quote, quote.id);

  @override
  Future<void> delete(String id) => _store.delete(id);

  @override
  Future<void> clear() => _store.clear();

  @override
  Future<List<Quote>> forClient(String clientId) async {
    final all = await this.all();
    return all.where((q) => q.clientId == clientId).toList();
  }

  @override
  Stream<List<Quote>> watchAll() async* {
    yield await all();
    await for (final _ in Stream<void>.periodic(const Duration(seconds: 5))) {
      yield await all();
    }
  }
}
