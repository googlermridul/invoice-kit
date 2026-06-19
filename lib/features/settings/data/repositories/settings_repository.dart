import 'dart:async';

import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/features/settings/domain/entities/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
  Future<void> clear();
  Stream<AppSettings> watch();
}

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required this._storage,
    StreamController<AppSettings>? controller,
  }) : _controller = controller ?? StreamController<AppSettings>.broadcast();

  static const _box = 'settings_box';
  static const _key = 'settings';

  final HiveStorageService _storage;
  final StreamController<AppSettings> _controller;

  @override
  Future<AppSettings> load() async {
    final box = await _storage.openBox<dynamic>(_box);
    final raw = box.get(_key);
    if (raw is Map) return AppSettings.fromJson(Map<String, dynamic>.from(raw));
    return const AppSettings();
  }

  @override
  Future<void> save(AppSettings settings) async {
    final box = await _storage.openBox<dynamic>(_box);
    await box.put(_key, settings.toJson());
    _controller.add(settings);
  }

  @override
  Future<void> clear() async {
    final box = await _storage.openBox<dynamic>(_box);
    await box.delete(_key);
    _controller.add(const AppSettings());
  }

  @override
  Stream<AppSettings> watch() => _controller.stream;
}
