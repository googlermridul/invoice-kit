import 'package:invoice_kit/features/authentication/domain/entities/user.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';

class RestoreSessionUseCase {
  RestoreSessionUseCase(this._repo);
  final AuthRepository _repo;

  Future<AuthSession?> call() => _repo.restoreSession();
}
