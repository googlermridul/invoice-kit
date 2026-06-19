part of 'backup_cubit.dart';

abstract class BackupEvent extends Equatable {
  const BackupEvent();
  @override
  List<Object?> get props => const [];
}

class BackupLoadRequested extends BackupEvent {
  const BackupLoadRequested();
}
