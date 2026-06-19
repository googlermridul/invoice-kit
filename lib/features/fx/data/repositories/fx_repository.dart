import 'dart:async';

import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/features/fx/data/datasources/fx_remote_datasource.dart';
import 'package:invoice_kit/features/fx/domain/entities/fx_rate.dart';

/// Local-first FX repository. On refresh it tries the dummy remote; otherwise
/// it returns whatever was last cached.
abstract class FxRepository {
  Future<List<FxRate>> all();
  Future<FxRate?> rate({required String base, required String quote});
  Future<List<FxRate>> refresh({String? base});
  Future<void> saveAll(List<FxRate> rates);
  Future<void> clear();
  Stream<List<FxRate>> watch();
}

class FxRepositoryImpl implements FxRepository {
  FxRepositoryImpl({
    required this._remote,
    required this._storage,
    StreamController<List<FxRate>>? controller,
  }) : _controller = controller ?? StreamController<List<FxRate>>.broadcast();

  static const _box = 'fx_rates_box';

  final FxRemoteDataSource _remote;
  final HiveStorageService _storage;
  final StreamController<List<FxRate>> _controller;

  @override
  Future<List<FxRate>> all() async {
    final box = await _storage.openBox<dynamic>(_box);
    final list = <FxRate>[];
    for (final raw in box.values) {
      if (raw is Map) list.add(FxRate.fromJson(Map<String, dynamic>.from(raw)));
    }
    return list;
  }

  @override
  Future<FxRate?> rate({required String base, required String quote}) async {
    final all = await this.all();
    try {
      return all.firstWhere(
        (r) => (r.base == base && r.quote == quote) || (r.base == quote && r.quote == base),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<FxRate>> refresh({String? base}) async {
    final fetched = await _remote.fetchRates(base: base ?? 'USD');
    await saveAll(fetched);
    return fetched;
  }

  @override
  Future<void> saveAll(List<FxRate> rates) async {
    final box = await _storage.openBox<dynamic>(_box);
    await box.clear();
    for (final r in rates) {
      await box.put('${r.base}_${r.quote}', r.toJson());
    }
    _controller.add(rates);
  }

  @override
  Future<void> clear() async {
    final box = await _storage.openBox<dynamic>(_box);
    await box.clear();
    _controller.add(const []);
  }

  @override
  Stream<List<FxRate>> watch() => _controller.stream;
}
