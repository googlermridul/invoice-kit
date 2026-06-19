import 'package:invoice_kit/core/errors/failures.dart';
import 'package:invoice_kit/features/authentication/domain/entities/user.dart';

/// Contract implemented by `data/repositories/auth_repository_impl.dart` and
/// consumed by the BLoC layer. Returning [Failure] keeps the BLoC free of
/// `try/catch` boilerplate.
abstract class AuthRepository {
  Future<({Failure? failure, AuthSession? session})> login({
    required String email,
    required String password,
  });

  Future<({Failure? failure, AuthSession? session})> register({
    required String email,
    required String password,
    String? name,
  });

  Future<({Failure? failure, User? user})> forgotPassword({required String email});

  Future<({Failure? failure, bool success})> logout();

  Future<User?> currentUser();

  Future<bool> isAuthenticated();
}
