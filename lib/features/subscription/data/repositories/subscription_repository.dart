import 'dart:async';

import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
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
    required this._localStorage,
    StreamController<SubscriptionStatus>? controller,
  }) : _controller =
           controller ?? StreamController<SubscriptionStatus>.broadcast();

  static const _box = 'subscription_box';
  static const _key = 'status';

  final SubscriptionRemoteDataSource _remote;
  final HiveStorageService _storage;
  final LocalStorageService _localStorage;
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

    // Mirror the trial start/expiry in SharedPreferences so other features
    // (e.g. the dashboard banner countdown) can read the dates without
    // round-tripping through the Hive box. Keeps a stable, user-visible
    // record of the active free trial window.
    if (status.trialStart != null) {
      await _localStorage.setString(
        StorageKeys.trialStart,
        status.trialStart!.toIso8601String(),
      );
    }
    if (status.trialEnd != null) {
      await _localStorage.setString(
        StorageKeys.trialEnd,
        status.trialEnd!.toIso8601String(),
      );
    } else {
      // A non-trialing state (e.g. paid or expired) clears the cached window
      // so a previously-started trial does not keep granting access.
      await _localStorage.remove(StorageKeys.trialStart);
      await _localStorage.remove(StorageKeys.trialEnd);
    }

    _controller.add(status);
  }

  @override
  Future<void> clear() async {
    final box = await _storage.openBox<dynamic>(_box);
    await box.delete(_key);
    await _localStorage.remove(StorageKeys.trialStart);
    await _localStorage.remove(StorageKeys.trialEnd);
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
