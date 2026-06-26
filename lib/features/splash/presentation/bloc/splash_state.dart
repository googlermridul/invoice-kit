import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();
}

class SplashInitial extends SplashState {
  const SplashInitial();

  @override
  List<Object> get props => [];
}

class SplashNavigateToOnboarding extends SplashState {
  const SplashNavigateToOnboarding();

  @override
  List<Object> get props => [];
}

class SplashNavigateToSubscription extends SplashState {
  const SplashNavigateToSubscription();

  @override
  List<Object> get props => [];
}

class SplashNavigateToAuth extends SplashState {
  const SplashNavigateToAuth();

  @override
  List<Object> get props => [];
}

class SplashNavigateToDevices extends SplashState {
  const SplashNavigateToDevices();

  @override
  List<Object> get props => [];
}

class SplashNavigateToHome extends SplashState {
  const SplashNavigateToHome();

  @override
  List<Object> get props => [];
}

class SplashError extends SplashState {
  const SplashError({required this.message});
  final String message;

  @override
  List<Object> get props => [message];
}
