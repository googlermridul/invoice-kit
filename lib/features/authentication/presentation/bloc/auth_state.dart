part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.message,
    this.isSubmitting = false,
  });

  final AuthStatus status;
  final User? user;
  final String? message;
  final bool isSubmitting;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? message,
    bool? isSubmitting,
    bool clearUser = false,
    bool clearMessage = false,
  }) => AuthState(
    status: status ?? this.status,
    user: clearUser ? null : (user ?? this.user),
    message: clearMessage ? null : (message ?? this.message),
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );

  @override
  List<Object?> get props => [status, user, message, isSubmitting];
}
