part of 'devices_cubit.dart';

abstract class DevicesEvent extends Equatable {
  const DevicesEvent();
  @override
  List<Object?> get props => const [];
}

class DevicesLoadRequested extends DevicesEvent {
  const DevicesLoadRequested(this.userId);
  final String userId;
  @override
  List<Object?> get props => [userId];
}

class DevicesRemoveRequested extends DevicesEvent {
  const DevicesRemoveRequested(this.deviceId);
  final String deviceId;
  @override
  List<Object?> get props => [deviceId];
}
