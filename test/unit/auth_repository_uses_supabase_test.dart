import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/errors/error_handler.dart';
import 'package:invoice_kit/core/errors/error_mapper.dart';
import 'package:invoice_kit/core/network/interceptors/auth_interceptor.dart';
import 'package:invoice_kit/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:invoice_kit/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:invoice_kit/features/authentication/data/datasources/supabase_auth_datasource.dart';
import 'package:invoice_kit/features/authentication/data/models/auth_session_model.dart';
import 'package:invoice_kit/features/authentication/data/models/user_model.dart';
import 'package:invoice_kit/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockSupabaseAuth extends Mock implements SupabaseAuthDataSource {}

class _MockAuthLocal extends Mock implements AuthLocalDataSource {}

class _MockAuthRemote extends Mock implements AuthRemoteDataSource {}

class _MockTokenProvider extends Mock implements TokenProvider {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      AuthSessionModel(
        accessToken: '',
        refreshToken: '',
        user: const UserModel(id: '', email: ''),
      ),
    );
  });

  late _MockSupabaseAuth supabase;
  late _MockAuthLocal local;
  late _MockAuthRemote remote;
  late _MockTokenProvider tokenProvider;
  late AuthRepositoryImpl repo;

  AuthSessionModel makeSession({String id = 'u1', String email = 'a@b.com'}) {
    return AuthSessionModel(
      accessToken: 'access-$id',
      refreshToken: 'refresh-$id',
      user: UserModel(id: id, email: email),
    );
  }

  setUp(() {
    supabase = _MockSupabaseAuth();
    local = _MockAuthLocal();
    remote = _MockAuthRemote();
    tokenProvider = _MockTokenProvider();

    when(
      () => tokenProvider.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => tokenProvider.clearTokens()).thenAnswer((_) async {});
    when(() => local.cacheSession(any())).thenAnswer((_) async {});

    repo = AuthRepositoryImpl(
      supabase: supabase,
      local: local,
      errorHandler: ErrorHandler(const DefaultErrorMapper()),
      tokenProvider: tokenProvider,
    );
  });

  test('login uses Supabase and never the legacy Dio remote', () async {
    when(
      () => supabase.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => makeSession());

    final result = await repo.login(email: 'a@b.com', password: 'pw');

    expect(result.failure, isNull);
    expect(result.session, isNotNull);
    expect(result.session!.user.email, 'a@b.com');
    verify(
      () => supabase.signInWithEmail(
        email: 'a@b.com',
        password: 'pw',
      ),
    ).called(1);
    verifyNever(
      () => remote.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('register uses Supabase and never the legacy Dio remote', () async {
    when(
      () => supabase.signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) async => makeSession(email: 'new@b.com'));

    final result = await repo.register(
      email: 'new@b.com',
      password: 'pw',
      name: 'New',
    );

    expect(result.failure, isNull);
    expect(result.session!.user.email, 'new@b.com');
    verify(
      () => supabase.signUpWithEmail(
        email: 'new@b.com',
        password: 'pw',
        name: 'New',
      ),
    ).called(1);
    verifyNever(
      () => remote.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
        name: any(named: 'name'),
      ),
    );
  });

  test(
    'forgotPassword uses Supabase and never the legacy Dio remote',
    () async {
      when(
        () => supabase.sendPasswordReset(email: any(named: 'email')),
      ).thenAnswer((_) async {});

      final result = await repo.forgotPassword(email: 'a@b.com');

      expect(result.failure, isNull);
      verify(() => supabase.sendPasswordReset(email: 'a@b.com')).called(1);
      verifyNever(() => remote.forgotPassword(email: any(named: 'email')));
    },
  );

  test('signInWithGoogle uses Supabase', () async {
    when(() => supabase.signInWithGoogle()).thenAnswer((_) async => makeSession());

    final result = await repo.signInWithGoogle();

    expect(result.failure, isNull);
    expect(result.session, isNotNull);
    verify(() => supabase.signInWithGoogle()).called(1);
  });

  test(
    'logout always wipes local state, even if Supabase signOut fails',
    () async {
      when(() => supabase.signOut()).thenThrow(Exception('Supabase down'));
      when(() => local.clear()).thenAnswer((_) async {});

      final result = await repo.logout();

      expect(result.failure, isNull);
      expect(result.success, isTrue);
      verify(() => supabase.signOut()).called(1);
      verify(() => local.clear()).called(1);
      verify(() => tokenProvider.clearTokens()).called(1);
    },
  );

  test(
    'login surfaces Supabase errors via ErrorHandler (no Dio fallback)',
    () async {
      when(
        () => supabase.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('Supabase auth failure'));

      final result = await repo.login(email: 'a@b.com', password: 'pw');

      expect(result.failure, isNotNull);
      expect(result.session, isNull);
      // Crucially: we must NOT have silently fallen back to Dio, which would
      // hit APP_BASE_URL and mask the real Supabase error.
      verifyNever(
        () => remote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    },
  );
}
