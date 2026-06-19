part of 'settings_cubit.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => const [];
}

class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}
