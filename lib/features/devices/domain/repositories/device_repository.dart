import 'package:invoice_kit/features/devices/domain/entities/device.dart';

abstract class DeviceRepository {
  Future<List<Device>> fetchDevices({required String userId});
  Future<Device> registerDevice({
    required String userId,
    required String deviceId,
    required String deviceName,
    required String platform,
  });
  Future<void> removeDevice({required String deviceId});
  Future<bool> enforceDeviceLimit({
    required String userId,
    required int maxDevices,
  });
  Future<String> currentDeviceId();
  Future<void> setCurrentDeviceId(String deviceId);
}
