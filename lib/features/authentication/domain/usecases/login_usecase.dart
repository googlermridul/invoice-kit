import 'package:flutter_boilerplate/core/errors/failures.dart';
import 'package:flutter_boilerplate/features/authentication/domain/entities/user.dart';
import 'package:flutter_boilerplate/features/authentication/domain/repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repo);
  final AuthRepository _repo;

  Future<({Failure? failure, AuthSession? session})> call({
    required String email,
    required String password,
  }) => _repo.login(email: email, password: password);
}
