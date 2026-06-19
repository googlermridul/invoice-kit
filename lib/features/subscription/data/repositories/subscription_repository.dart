import 'dart:async';

import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';

/// Caches the latest subscription status locally and falls back to the
/// remote (dummy) endpoint when refreshed.
abstract class SubscriptionRepository {
  Future<SubscriptionStatus> current();
  Future<void> save(SubscriptionStatus status);
  Future<void> clear();
  Future<SubscriptionStatus> refresh();
  Stream<SubscriptionStatus> watch();
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({
    required this._remote,
    required this._storage,
    StreamController<SubscriptionStatus>? controller,
  }) : _controller = controller ?? StreamController<SubscriptionStatus>.broadcast();

  static const _box = 'subscription_box';
  static const _key = 'status';

  final SubscriptionRemoteDataSource _remote;
  final HiveStorageService _storage;
  final StreamController<SubscriptionStatus> _controller;

  @override
  Future<SubscriptionStatus> current() async {
    final box = await _storage.openBox<dynamic>(_box);
    final raw = box.get(_key);
    if (raw is Map) {
      return SubscriptionStatus.fromJson(Map<String, dynamic>.from(raw));
    }
    return SubscriptionStatus.initial();
  }

  @override
  Future<void> save(SubscriptionStatus status) async {
    final box = await _storage.openBox<dynamic>(_box);
    await box.put(_key, status.toJson());
    _controller.add(status);
  }

  @override
  Future<void> clear() async {
    final box = await _storage.openBox<dynamic>(_box);
    await box.delete(_key);
    _controller.add(SubscriptionStatus.initial());
  }

  @override
  Future<SubscriptionStatus> refresh() async {
    final remote = await _remote.fetchStatus();
    await save(remote);
    return remote;
  }

  @override
  Stream<SubscriptionStatus> watch() => _controller.stream;
}
