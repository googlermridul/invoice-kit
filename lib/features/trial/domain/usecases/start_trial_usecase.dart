import 'package:invoice_kit/features/trial/domain/entities/trial_state.dart';
import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';

class StartTrialUseCase {
  StartTrialUseCase(this._repo);
  final TrialRepository _repo;

  Future<TrialState> call({required DateTime now}) =>
      _repo.startTrial(now: now);
}
