import 'package:invoice_kit/core/errors/failures.dart';
import 'package:invoice_kit/features/authentication/domain/entities/user.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._repo);
  final AuthRepository _repo;

  Future<({Failure? failure, AuthSession? session})> call({
    required String email,
    required String password,
    String? name,
  }) => _repo.register(email: email, password: password, name: name);
}
