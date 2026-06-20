part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.loading = false,
    this.settings = const AppSettings(),
  });

  factory SettingsState.initial() => const SettingsState();

  final bool loading;
  final AppSettings settings;

  SettingsState copyWith({bool? loading, AppSettings? settings}) =>
      SettingsState(
        loading: loading ?? this.loading,
        settings: settings ?? this.settings,
      );

  @override
  List<Object?> get props => [loading, settings];
}
