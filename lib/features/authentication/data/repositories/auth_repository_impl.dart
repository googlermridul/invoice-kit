import 'package:invoice_kit/core/errors/error_handler.dart';
import 'package:invoice_kit/core/errors/failures.dart';
import 'package:invoice_kit/core/network/interceptors/auth_interceptor.dart';
import 'package:invoice_kit/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:invoice_kit/features/authentication/data/datasources/supabase_auth_datasource.dart';
import 'package:invoice_kit/features/authentication/data/models/auth_session_model.dart';
import 'package:invoice_kit/features/authentication/data/models/user_model.dart';
import 'package:invoice_kit/features/authentication/domain/entities/user.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';

/// Auth repository facade.
///
/// Talks **exclusively** to Supabase for auth (sign-up, sign-in, Google,
/// password reset, sign-out, session restore). The previous version of this
/// class silently fell back to the legacy Dio-backed `AuthRemoteDataSource`
/// when Supabase failed — that fallback was wrong because Dio was pointed at
/// `APP_BASE_URL` (a placeholder), which produced a generic 404/network error
/// that masked the real Supabase failure.
///
/// Supabase auth/database calls must go through the Supabase Flutter client.
/// `AuthRemoteDataSourceImpl` is preserved in DI for compile compatibility
/// with non-auth legacy callers but is no longer invoked from this file.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._supabase,
    required this._local,
    required this._errorHandler,
    required this._tokenProvider,
  });

  final SupabaseAuthDataSource _supabase;
  final AuthLocalDataSource _local;
  final ErrorHandler _errorHandler;
  final TokenProvider _tokenProvider;

  @override
  Future<({Failure? failure, AuthSession? session})> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _supabase.signInWithEmail(
        email: email,
        password: password,
      );
      await _cache(session);
      return (failure: null, session: session);
    } on Object catch (e, st) {
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
      final session = await _supabase.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      await _cache(session);
      return (failure: null, session: session);
    } on Object catch (e, st) {
      return (failure: _errorHandler.map(e, st), session: null);
    }
  }

  @override
  Future<({Failure? failure, AuthSession? session})> signInWithGoogle() async {
    try {
      final session = await _supabase.signInWithGoogle();
      if (session == null) {
        return const (failure: null, session: null);
      }
      await _cache(session);
      return (failure: null, session: session);
    } on Object catch (e, st) {
      return (failure: _errorHandler.map(e, st), session: null);
    }
  }

  @override
  Future<({Failure? failure, User? user})> forgotPassword({
    required String email,
  }) async {
    try {
      await _supabase.sendPasswordReset(email: email);
      return (failure: null, user: null);
    } on Object catch (e, st) {
      return (failure: _errorHandler.map(e, st), user: null);
    }
  }

  @override
  Future<({Failure? failure, bool success})> logout() async {
    try {
      await _supabase.signOut();
    } on Object catch (_) {
      // Local state must still be wiped even if the remote sign-out fails.
    }
    await _local.clear();
    await _tokenProvider.clearTokens();
    return (failure: null, success: true);
  }

  @override
  Future<({Failure? failure, bool success})> deleteAccount() async {
    try {
      await _supabase.deleteAccount();
      await _local.clear();
      await _tokenProvider.clearTokens();
      return (failure: null, success: true);
    } on Object catch (e, st) {
      return (failure: _errorHandler.map(e, st), success: false);
    }
  }

  @override
  Future<User?> currentUser() async {
    final supa = await _supabase.currentSession();
    if (supa != null) return supa.user;
    final cached = await _local.readSession();
    return cached?.user;
  }

  @override
  Future<bool> isAuthenticated() async {
    final supa = await _supabase.currentSession();
    if (supa != null) return true;
    final token = await _tokenProvider.accessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final supa = await _supabase.currentSession();
    if (supa != null) return supa;
    return _local.readSession();
  }

  Future<void> _cache(AuthSession session) async {
    await _local.cacheSession(
      AuthSessionModel(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        user: UserModel.fromEntity(session.user),
      ),
    );
    await _tokenProvider.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
  }
}
