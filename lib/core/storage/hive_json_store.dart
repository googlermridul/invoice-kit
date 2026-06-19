import 'package:hive_flutter/hive_flutter.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';

/// Generic typed helper for storing JSON-encoded values in a Hive box.
class HiveJsonStore<T> {
  HiveJsonStore({required this.storage, required this.boxName, required this.fromJson, required this.toJson});

  final HiveStorageService storage;
  final String boxName;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  Future<Box<dynamic>> _box() async => storage.openBox<dynamic>(boxName);

  Future<List<T>> all() async {
    final box = await _box();
    final list = <T>[];
    for (final raw in box.values) {
      if (raw is Map) {
        list.add(fromJson(Map<String, dynamic>.from(raw)));
      }
    }
    return list;
  }

  Future<T?> byId(String id) async {
    final box = await _box();
    final raw = box.get(id);
    if (raw is Map) return fromJson(Map<String, dynamic>.from(raw));
    return null;
  }

  Future<void> save(T item, String id) async {
    final box = await _box();
    await box.put(id, toJson(item));
  }

  Future<void> delete(String id) async {
    final box = await _box();
    await box.delete(id);
  }

  Future<void> clear() async {
    final box = await _box();
    await box.clear();
  }

  Future<void> putAll(List<T> items, String Function(T) idOf) async {
    final box = await _box();
    final map = {for (final item in items) idOf(item): toJson(item)};
    await box.putAll(map);
  }
}
