import 'package:invoice_kit/features/devices/domain/entities/device.dart';
import 'package:invoice_kit/features/devices/domain/repositories/device_repository.dart';

class RegisterDeviceUseCase {
  RegisterDeviceUseCase(this._repo);
  final DeviceRepository _repo;

  Future<Device> call({
    required String userId,
    required String deviceId,
    required String deviceName,
    required String platform,
  }) => _repo.registerDevice(
    userId: userId,
    deviceId: deviceId,
    deviceName: deviceName,
    platform: platform,
  );
}
