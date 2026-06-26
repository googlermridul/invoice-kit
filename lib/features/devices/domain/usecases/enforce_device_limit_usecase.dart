import 'package:invoice_kit/features/devices/domain/repositories/device_repository.dart';

class EnforceDeviceLimitUseCase {
  EnforceDeviceLimitUseCase(this._repo);
  final DeviceRepository _repo;

  Future<bool> call({required String userId, required int maxDevices}) =>
      _repo.enforceDeviceLimit(userId: userId, maxDevices: maxDevices);
}
