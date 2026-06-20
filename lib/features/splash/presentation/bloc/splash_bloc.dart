import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/features/splash/presentation/bloc/splash_event.dart';
import 'package:invoice_kit/features/splash/presentation/bloc/splash_state.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({
    required this.localStorage,
    required this.subscriptionRepository,
  }) : super(SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
    on<AppInitializationFailed>(_onAppInitializationFailed);
  }

  final LocalStorageService localStorage;
  final SubscriptionRepository subscriptionRepository;

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    try {
      final onboardingCompleted =
          localStorage.getBool(StorageKeys.onboardingCompleted) ?? false;

      if (!onboardingCompleted) {
        emit(const SplashNavigateToOnboarding());
        return;
      }

      final status = await subscriptionRepository.current();
      final now = DateTime.now();

      final hasAccess = status.hasAccess(now);

      if (hasAccess) {
        emit(const SplashNavigateToHome());
      } else {
        emit(const SplashNavigateToSubscription());
      }
    } catch (e) {
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
