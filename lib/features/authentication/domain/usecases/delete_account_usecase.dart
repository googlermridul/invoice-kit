import 'package:invoice_kit/core/errors/failures.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';

class DeleteAccountUseCase {
  DeleteAccountUseCase(this._repo);
  final AuthRepository _repo;

  Future<({Failure? failure, bool success})> call() => _repo.deleteAccount();
}
