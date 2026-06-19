import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SplashEvent extends Equatable {}

class NavigateToHome extends SplashEvent {
  @override
  List<Object> get props => [];
}

abstract class SplashState extends Equatable {}

class SplashInitial extends SplashState {
  @override
  List<Object> get props => [];
}

class SplashLoaded extends SplashState {
  SplashLoaded({required this.nextRoute});
  final String nextRoute;

  @override
  List<Object> get props => [nextRoute];
}

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial());

  Stream<SplashState> mapEventToState(SplashEvent event) async* {
    if (event is NavigateToHome) {
      yield SplashLoaded(nextRoute: '/home');
      yield SplashInitial();
    }
  }
}
