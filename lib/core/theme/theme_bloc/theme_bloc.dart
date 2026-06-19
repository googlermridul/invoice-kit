import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc(this._localStorage)
    : super(
        ThemeState(
          mode: _resolveMode(_localStorage.getString(StorageKeys.themeMode)),
        ),
      ) {
    on<ThemeChanged>(_onChanged);
    on<ThemeToggled>(_onToggled);
  }

  final LocalStorageService _localStorage;

  Future<void> _onChanged(ThemeChanged event, Emitter<ThemeState> emit) async {
    await _localStorage.setString(StorageKeys.themeMode, event.mode.name);
    emit(state.copyWith(mode: event.mode));
  }

  Future<void> _onToggled(ThemeToggled event, Emitter<ThemeState> emit) async {
    final next = state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _localStorage.setString(StorageKeys.themeMode, next.name);
    emit(state.copyWith(mode: next));
  }

  static ThemeMode _resolveMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
