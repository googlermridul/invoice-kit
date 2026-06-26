part of 'devices_cubit.dart';

enum DevicesStatus { initial, loading, ready }

class DevicesState extends Equatable {
  const DevicesState({
    this.status = DevicesStatus.initial,
    this.devices = const [],
    this.error,
  });

  factory DevicesState.initial() => const DevicesState();

  final DevicesStatus status;
  final List<Device> devices;
  final String? error;

  DevicesState copyWith({
    DevicesStatus? status,
    List<Device>? devices,
    String? error,
    bool clearError = false,
  }) {
    return DevicesState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, devices, error];
}
