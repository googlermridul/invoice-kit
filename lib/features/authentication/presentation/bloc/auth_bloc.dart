import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/authentication/domain/entities/user.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/login_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/register_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required AuthRepository repository,
  }) : _login = loginUseCase,
       _register = registerUseCase,
       _logout = logoutUseCase,
       _forgot = forgotPasswordUseCase,
       _repo = repository,
       super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthForgotPasswordRequested>(_onForgot);
    on<AuthLogoutRequested>(_onLogout);
  }

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final ForgotPasswordUseCase _forgot;
  final AuthRepository _repo;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final isAuth = await _repo.isAuthenticated();
    if (isAuth) {
      final user = await _repo.currentUser();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user, clearUser: user == null));
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    final result = await _login(email: event.email, password: event.password);
    if (result.failure != null) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          message: result.failure!.message,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: result.session?.user,
        isSubmitting: false,
        clearMessage: true,
      ),
    );
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    final result = await _register(email: event.email, password: event.password, name: event.name);
    if (result.failure != null) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          message: result.failure!.message,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: result.session?.user,
        isSubmitting: false,
        clearMessage: true,
      ),
    );
  }

  Future<void> _onForgot(AuthForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    final result = await _forgot(email: event.email);
    if (result.failure != null) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          isSubmitting: false,
          message: result.failure!.message,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        message: 'Reset link sent. Please check your inbox.',
      ),
    );
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true));
    await _logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
