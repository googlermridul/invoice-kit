import 'package:flutter_boilerplate/core/errors/error_handler.dart';
import 'package:flutter_boilerplate/core/errors/failures.dart';
import 'package:flutter_boilerplate/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_boilerplate/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:flutter_boilerplate/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_boilerplate/features/authentication/domain/entities/user.dart';
import 'package:flutter_boilerplate/features/authentication/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._remote,
    required this._local,
    required this._errorHandler,
    required this._tokenProvider,
  });

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final ErrorHandler _errorHandler;
  final TokenProvider _tokenProvider;

  @override
  Future<({Failure? failure, AuthSession? session})> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _remote.login(email: email, password: password);
      await _local.cacheSession(session);
      await _tokenProvider.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return (failure: null, session: session);
    } catch (e, st) {
      return (failure: _errorHandler.map(e, st), session: null);
    }
  }

  @override
  Future<({Failure? failure, AuthSession? session})> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final session = await _remote.register(email: email, password: password, name: name);
      await _local.cacheSession(session);
      await _tokenProvider.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return (failure: null, session: session);
    } catch (e, st) {
      return (failure: _errorHandler.map(e, st), session: null);
    }
  }

  @override
  Future<({Failure? failure, User? user})> forgotPassword({required String email}) async {
    try {
      await _remote.forgotPassword(email: email);
      return (failure: null, user: null);
    } catch (e, st) {
      return (failure: _errorHandler.map(e, st), user: null);
    }
  }

  @override
  Future<({Failure? failure, bool success})> logout() async {
    try {
      await _remote.logout();
      return (failure: null, success: true);
    } catch (_) {
      // Even if remote logout fails, clear local state.
    } finally {
      await _local.clear();
      await _tokenProvider.clearTokens();
    }
    return (failure: null, success: true);
  }

  @override
  Future<User?> currentUser() async {
    final session = await _local.readSession();
    return session?.user;
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _tokenProvider.accessToken();
    return token != null && token.isNotEmpty;
  }
}
