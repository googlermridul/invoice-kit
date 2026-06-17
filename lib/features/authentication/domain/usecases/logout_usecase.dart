import 'package:flutter_boilerplate/core/errors/failures.dart';
import 'package:flutter_boilerplate/features/authentication/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  LogoutUseCase(this._repo);
  final AuthRepository _repo;

  Future<({Failure? failure, bool success})> call() => _repo.logout();
}
