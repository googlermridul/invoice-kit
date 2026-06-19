import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/errors/failures.dart';
import 'package:invoice_kit/features/authentication/domain/entities/user.dart';
import 'package:invoice_kit/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late MockLoginUseCase loginUseCase;
  late MockRegisterUseCase registerUseCase;
  late MockLogoutUseCase logoutUseCase;
  late MockForgotPasswordUseCase forgotUseCase;

  setUp(() {
    repository = MockAuthRepository();
    loginUseCase = MockLoginUseCase();
    registerUseCase = MockRegisterUseCase();
    logoutUseCase = MockLogoutUseCase();
    forgotUseCase = MockForgotPasswordUseCase();
  });

  AuthBloc build() => AuthBloc(
    loginUseCase: loginUseCase,
    registerUseCase: registerUseCase,
    logoutUseCase: logoutUseCase,
    forgotPasswordUseCase: forgotUseCase,
    repository: repository,
  );

  const session = AuthSession(
    accessToken: 'a',
    refreshToken: 'r',
    user: User(id: '1', email: 'jane@example.com'),
  );

  blocTest<AuthBloc, AuthState>(
    'emits authenticated when login succeeds',
    setUp: () {
      when(
        () => loginUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => (failure: null, session: session));
    },
    build: build,
    act: (b) => b.add(const AuthLoginRequested(email: 'jane@example.com', password: 'secret')),
    expect: () => [
      isA<AuthState>()
          .having((s) => s.isSubmitting, 'submitting', isTrue)
          .having((s) => s.message, 'message', isNull),
      isA<AuthState>().having((s) => s.isAuthenticated, 'authenticated', isTrue),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits failure when login fails',
    setUp: () {
      when(
        () => loginUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => (failure: const ApiFailure(message: 'Bad creds'), session: null));
    },
    build: build,
    act: (b) => b.add(const AuthLoginRequested(email: 'jane@example.com', password: 'wrong')),
    expect: () => [
      isA<AuthState>().having((s) => s.isSubmitting, 'submitting', isTrue),
      isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.failure)
          .having((s) => s.message, 'message', 'Bad creds'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'logout resets state',
    setUp: () {
      when(() => logoutUseCase()).thenAnswer((_) async => (failure: null, success: true));
    },
    build: build,
    act: (b) => b.add(const AuthLogoutRequested()),
    expect: () => [
      isA<AuthState>().having((s) => s.isSubmitting, 'submitting', isTrue),
      isA<AuthState>().having((s) => s.status, 'status', AuthStatus.unauthenticated),
    ],
  );
}
