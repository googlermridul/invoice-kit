import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/features/trial/domain/entities/trial_state.dart';
import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';

class TrialRepositoryImpl implements TrialRepository {
  TrialRepositoryImpl(this._hive);

  static const String _key = 'state';

  final HiveStorageService _hive;

  @override
  Future<TrialState?> currentTrial() async {
    final box = await _hive.openBox<dynamic>(HiveBoxes.trial);
    final raw = box.get(_key);
    if (raw is Map) {
      return TrialState.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  @override
  Future<bool> isActive({DateTime? now}) async {
    final trial = await currentTrial();
    final nowTs = now ?? DateTime.now();
    return trial?.isActive(nowTs) ?? false;
  }

  @override
  Future<int> daysRemaining({DateTime? now}) async {
    final trial = await currentTrial();
    final nowTs = now ?? DateTime.now();
    return trial?.daysRemaining(nowTs) ?? 0;
  }

  @override
  Future<TrialState> startTrial({required DateTime now}) async {
    final box = await _hive.openBox<dynamic>(HiveBoxes.trial);
    final existing = await currentTrial();
    if (existing != null && existing.isActive(now)) {
      return existing;
    }
    final fresh = TrialState.fresh(now);
    await box.put(_key, fresh.toJson());
    return fresh;
  }

  @override
  Future<void> expireTrial() async {
    final existing = await currentTrial();
    if (existing == null) return;
    final box = await _hive.openBox<dynamic>(HiveBoxes.trial);
    await box.put(_key, existing.markExpired().toJson());
  }

  @override
  Future<void> clear() async {
    final box = await _hive.openBox<dynamic>(HiveBoxes.trial);
    await box.delete(_key);
  }
}
