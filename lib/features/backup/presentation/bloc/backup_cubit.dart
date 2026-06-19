import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/backup/data/repositories/backup_repository.dart';
import 'package:invoice_kit/features/backup/domain/entities/export_record.dart';
import 'package:invoice_kit/features/backup/domain/usecases/backup_validator.dart';

part 'backup_event.dart';
part 'backup_state.dart';

class BackupCubit extends Cubit<BackupState> {
  BackupCubit({required this.repository}) : super(BackupState.initial());

  final BackupRepository repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final history = await repository.history();
    emit(state.copyWith(loading: false, history: history));
  }

  Future<String> export() async {
    emit(state.copyWith(busy: true, error: null));
    try {
      final path = await repository.exportToFile();
      emit(state.copyWith(busy: false, lastExportPath: path, message: 'Exported backup'));
      await load();
      return path;
    } catch (e) {
      emit(state.copyWith(busy: false, error: e.toString()));
      rethrow;
    }
  }

  Future<Uint8List> exportBytes() => repository.exportJson();

  Future<BackupValidationResult> validate(String jsonString) =>
      repository.validate(jsonString);

  Future<ImportSummary> importFromString(String jsonString, {bool overwrite = true}) async {
    emit(state.copyWith(busy: true, error: null));
    try {
      final summary = await repository.importFromString(jsonString, overwrite: overwrite);
      emit(state.copyWith(busy: false, lastImport: summary, message: 'Imported backup'));
      return summary;
    } catch (e) {
      emit(state.copyWith(busy: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> wipeAll() async {
    emit(state.copyWith(busy: true));
    await repository.wipeAll();
    emit(state.copyWith(busy: false, message: 'All local data deleted'));
  }

  Future<void> clearHistory() => repository.clearHistory();
}
