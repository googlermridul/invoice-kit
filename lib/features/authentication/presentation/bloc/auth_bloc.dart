import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/authentication/domain/entities/user.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/delete_account_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/google_signin_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/login_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/register_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/restore_session_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required GoogleSignInUseCase googleSignInUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required AuthRepository repository,
  }) : _login = loginUseCase,
       _register = registerUseCase,
       _logout = logoutUseCase,
       _forgot = forgotPasswordUseCase,
       _google = googleSignInUseCase,
       _restore = restoreSessionUseCase,
       _delete = deleteAccountUseCase,
       super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthGoogleSignInRequested>(_onGoogle);
    on<AuthRestoreSessionRequested>(_onRestore);
    on<AuthForgotPasswordRequested>(_onForgot);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthDeleteAccountRequested>(_onDelete);
  }

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final ForgotPasswordUseCase _forgot;
  final GoogleSignInUseCase _google;
  final RestoreSessionUseCase _restore;
  final DeleteAccountUseCase _delete;

  Future<void> _onStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final session = await _restore();
    if (session != null) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
        ),
      );
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onRestore(
    AuthRestoreSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    final session = await _restore();
    if (session != null) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
        ),
      );
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
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

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    final result = await _register(
      email: event.email,
      password: event.password,
      name: event.name,
    );
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

  Future<void> _onGoogle(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    final result = await _google();
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
    if (result.session == null) {
      // Cancelled by user.
      emit(state.copyWith(isSubmitting: false));
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.authenticated,
        user: result.session!.user,
        isSubmitting: false,
        clearMessage: true,
      ),
    );
  }

  Future<void> _onForgot(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
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

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    await _logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onDelete(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    final result = await _delete();
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
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
