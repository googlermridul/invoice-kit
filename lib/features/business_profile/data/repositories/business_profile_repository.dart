import 'dart:async';

import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/hive_json_store.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';

abstract class BusinessProfileRepository {
  Future<BusinessProfile?> load();
  Future<void> save(BusinessProfile profile);
  Future<void> clear();
  Stream<BusinessProfile?> watch();
}

class BusinessProfileRepositoryImpl implements BusinessProfileRepository {
  BusinessProfileRepositoryImpl(this._store, {StreamController<BusinessProfile?>? controller})
      : _controller = controller ?? StreamController<BusinessProfile?>.broadcast();

  static const _id = 'me';
  final HiveJsonStore<BusinessProfile> _store;
  final StreamController<BusinessProfile?> _controller;

  static BusinessProfileRepository create(HiveStorageService storage) =>
      BusinessProfileRepositoryImpl(
        HiveJsonStore<BusinessProfile>(
          storage: storage,
          boxName: HiveBoxes.businessProfile,
          fromJson: BusinessProfile.fromJson,
          toJson: (p) => p.toJson(),
        ),
      );

  @override
  Future<BusinessProfile?> load() => _store.byId(_id);

  @override
  Future<void> save(BusinessProfile profile) async {
    await _store.save(profile, _id);
    _controller.add(profile);
  }

  @override
  Future<void> clear() async {
    await _store.delete(_id);
    _controller.add(null);
  }

  @override
  Stream<BusinessProfile?> watch() => _controller.stream;
}
