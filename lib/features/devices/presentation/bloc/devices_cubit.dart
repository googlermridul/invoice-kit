import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/core/errors/error_handler.dart';
import 'package:invoice_kit/features/devices/domain/entities/device.dart';
import 'package:invoice_kit/features/devices/domain/usecases/fetch_devices_usecase.dart';
import 'package:invoice_kit/features/devices/domain/usecases/remove_device_usecase.dart';

part 'devices_event.dart';
part 'devices_state.dart';

class DevicesCubit extends Cubit<DevicesState> {
  DevicesCubit({
    required this._fetchDevices,
    required this._removeDevice,
    required this._errorHandler,
  }) : super(DevicesState.initial());

  final FetchDevicesUseCase _fetchDevices;
  final RemoveDeviceUseCase _removeDevice;
  final ErrorHandler _errorHandler;

  Future<void> load(String userId) async {
    emit(state.copyWith(status: DevicesStatus.loading, clearError: true));
    final result = await _errorHandler.run<List<Device>>(
      () => _fetchDevices(userId: userId),
    );
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(status: DevicesStatus.ready, devices: value));
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: DevicesStatus.ready,
            error: failure.message,
          ),
        );
    }
  }

  Future<void> remove(String deviceId) async {
    final previous = state.devices;
    final optimistic = previous.where((d) => d.deviceId != deviceId).toList();
    emit(state.copyWith(devices: optimistic));
    final result = await _errorHandler.run<void>(
      () => _removeDevice(deviceId: deviceId),
    );
    switch (result) {
      case Success():
        // Optimistic state already applied.
        break;
      case FailureResult(:final failure):
        emit(
          state.copyWith(devices: previous, error: failure.message),
        );
    }
  }
}
