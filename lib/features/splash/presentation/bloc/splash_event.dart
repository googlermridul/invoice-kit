import 'package:equatable/equatable.dart';

abstract class SplashEvent extends Equatable {}

class SplashStarted extends SplashEvent {
  @override
  List<Object> get props => [];
}

class AppInitializationFailed extends SplashEvent {
  AppInitializationFailed(this.message);
  final String message;

  @override
  List<Object> get props => [message];
}
