import 'package:flutter_boilerplate/core/errors/failures.dart';
import 'package:flutter_boilerplate/features/authentication/domain/entities/user.dart';
import 'package:flutter_boilerplate/features/authentication/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  ForgotPasswordUseCase(this._repo);
  final AuthRepository _repo;

  Future<({Failure? failure, User? user})> call({required String email}) =>
      _repo.forgotPassword(email: email);
}
