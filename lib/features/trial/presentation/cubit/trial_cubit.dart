import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/trial/domain/entities/trial_state.dart';
import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';

part 'trial_state.dart';

/// Wraps [TrialRepository] for screens that just need to display the
/// current trial status (banner, splash, dashboard countdown).
class TrialCubit extends Cubit<TrialCubitState> {
  TrialCubit({required this._repository}) : super(const TrialCubitState._()) {
    refresh();
  }

  final TrialRepository _repository;

  Future<void> refresh() async {
    emit(state.copyWith(loading: true));
    final trial = await _repository.currentTrial();
    emit(
      state.copyWith(
        loading: false,
        trial: trial,
        active: trial?.isActive(DateTime.now()) ?? false,
      ),
    );
  }

  Future<void> startIfMissing() async {
    final existing = await _repository.currentTrial();
    if (existing != null && existing.isActive(DateTime.now())) {
      emit(
        state.copyWith(
          loading: false,
          trial: existing,
          active: true,
        ),
      );
      return;
    }
    final fresh = await _repository.startTrial(now: DateTime.now());
    emit(
      state.copyWith(
        loading: false,
        trial: fresh,
        active: true,
      ),
    );
  }
}
