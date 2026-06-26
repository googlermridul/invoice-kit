import 'package:invoice_kit/features/devices/domain/repositories/device_repository.dart';

class RemoveDeviceUseCase {
  RemoveDeviceUseCase(this._repo);
  final DeviceRepository _repo;

  Future<void> call({required String deviceId}) =>
      _repo.removeDevice(deviceId: deviceId);
}
