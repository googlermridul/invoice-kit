import 'package:invoice_kit/features/devices/domain/entities/device.dart';
import 'package:invoice_kit/features/devices/domain/repositories/device_repository.dart';

class FetchDevicesUseCase {
  FetchDevicesUseCase(this._repo);
  final DeviceRepository _repo;

  Future<List<Device>> call({required String userId}) =>
      _repo.fetchDevices(userId: userId);
}
