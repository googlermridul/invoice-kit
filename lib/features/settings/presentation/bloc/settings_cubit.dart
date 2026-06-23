import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/settings/data/repositories/settings_repository.dart';
import 'package:invoice_kit/features/settings/domain/entities/app_settings.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required this.repository}) : super(SettingsState.initial());

  final SettingsRepository repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final settings = await repository.load();
    emit(state.copyWith(loading: false, settings: settings));
  }

  Future<void> save(AppSettings settings) async {
    await repository.save(settings);
    emit(state.copyWith(settings: settings));
  }

  Future<void> setCurrency(String code) async {
    final current = state.settings;
    final next = current.copyWith(currency: code);
    await save(next);
  }

  Future<void> setPdfTemplate(String templateId) async {
    final current = state.settings;
    final next = current.copyWith(selectedPdfTemplate: templateId);
    await save(next);
  }

  Future<void> setTaxInclusive({required bool value}) async {
    final next = state.settings.copyWith(taxInclusive: value);
    await save(next);
  }

  Future<void> setSendReminders({required bool value}) async {
    final next = state.settings.copyWith(sendReminders: value);
    await save(next);
  }

  Future<void> setMarkOverdueAuto({required bool value}) async {
    final next = state.settings.copyWith(markOverdueAuto: value);
    await save(next);
  }
}
