import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/services/startup_coordinator.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/features/splash/presentation/bloc/splash_event.dart';
import 'package:invoice_kit/features/splash/presentation/bloc/splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({
    required this._localStorage,
    required StartupCoordinator startupCoordinator,
  }) : _coordinator = startupCoordinator,
       super(SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
    on<AppInitializationFailed>(_onAppInitializationFailed);
  }

  final LocalStorageService _localStorage;
  final StartupCoordinator _coordinator;

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    try {
      final introCompleted =
          _localStorage.getBool(StorageKeys.introOnboardingCompleted) ??
          (_localStorage.getBool(StorageKeys.onboardingCompleted) ?? false);

      if (!introCompleted) {
        emit(const SplashNavigateToIntro());
        return;
      }

      final setupCompleted =
          _localStorage.getBool(StorageKeys.setupOnboardingCompleted) ??
          (_localStorage.getBool(StorageKeys.onboardingCompleted) ?? false);

      if (!setupCompleted) {
        emit(const SplashNavigateToOnboarding());
        return;
      }

      final decision = await _coordinator.run();

      emit(
        switch (decision.destination) {
          StartupDestination.home => const SplashNavigateToHome(),
          StartupDestination.onboarding => const SplashNavigateToOnboarding(),
          StartupDestination.trialExpired ||
          StartupDestination.auth => const SplashNavigateToAuth(),
          StartupDestination.subscription =>
            const SplashNavigateToSubscription(),
          StartupDestination.deviceManagement =>
            const SplashNavigateToDevices(),
        },
      );
    } on Exception catch (e) {
      add(AppInitializationFailed(e.toString()));
    }
  }

  void _onAppInitializationFailed(
    AppInitializationFailed event,
    Emitter<SplashState> emit,
  ) {
    emit(SplashError(message: event.message));
  }
}
