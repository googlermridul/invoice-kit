import 'package:invoice_kit/features/trial/domain/entities/trial_state.dart';
import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';

class GetTrialStateUseCase {
  GetTrialStateUseCase(this._repo);
  final TrialRepository _repo;

  Future<TrialState?> call() => _repo.currentTrial();
}
