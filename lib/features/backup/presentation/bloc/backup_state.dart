part of 'backup_cubit.dart';

class BackupState extends Equatable {
  const BackupState({
    this.loading = false,
    this.busy = false,
    this.history = const [],
    this.lastExportPath,
    this.lastImport,
    this.message,
    this.error,
  });

  factory BackupState.initial() => const BackupState();

  final bool loading;
  final bool busy;
  final List<ExportRecord> history;
  final String? lastExportPath;
  final ImportSummary? lastImport;
  final String? message;
  final String? error;

  BackupState copyWith({
    bool? loading,
    bool? busy,
    List<ExportRecord>? history,
    String? lastExportPath,
    ImportSummary? lastImport,
    String? message,
    String? error,
    bool clearMessage = false,
    bool clearError = false,
  }) => BackupState(
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    history: history ?? this.history,
    lastExportPath: lastExportPath ?? this.lastExportPath,
    lastImport: lastImport ?? this.lastImport,
    message: clearMessage ? null : (message ?? this.message),
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [
    loading,
    busy,
    history,
    lastExportPath,
    lastImport,
    message,
    error,
  ];
}
