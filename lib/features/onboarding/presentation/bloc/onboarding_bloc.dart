import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/settings/data/repositories/settings_repository.dart';
import 'package:invoice_kit/features/settings/domain/entities/app_settings.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/domain/services/entitlement_service.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required this.localStorage,
    required this.businessRepo,
    required this.settingsRepo,
    required this.subscriptionRepo,
    required this.entitlements,
  }) : super(OnboardingState.initial()) {
    on<OnboardingStarted>(_onStarted);
    on<OnboardingStepChanged>(_onStepChanged);
    on<OnboardingUserNameChanged>(_onUserName);
    on<OnboardingBusinessNameChanged>(_onBusinessName);
    on<OnboardingCurrencyChanged>(_onCurrency);
    on<OnboardingTaxIdChanged>(_onTaxId);
    on<OnboardingPaymentTermsChanged>(_onTerms);
    on<OnboardingThemeChanged>(_onTheme);
    on<OnboardingCompleted>(_onCompleted);
  }

  final LocalStorageService localStorage;
  final BusinessProfileRepository businessRepo;
  final SettingsRepository settingsRepo;
  final SubscriptionRepository subscriptionRepo;
  final EntitlementService entitlements;

  Future<void> _onStarted(OnboardingStarted event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    final existingProfile = await businessRepo.load();
    final settings = await settingsRepo.load();
    emit(
      state.copyWith(
        status: OnboardingStatus.ready,
        userName: existingProfile?.ownerName ?? state.userName,
        businessName: existingProfile?.businessName ?? state.businessName,
        currency: existingProfile?.defaultCurrency ?? settings.currency,
        taxId: existingProfile?.taxId ?? state.taxId,
        paymentTerms: existingProfile?.defaultPaymentTerms ?? state.paymentTerms,
      ),
    );
  }

  void _onStepChanged(OnboardingStepChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(step: event.step));
  }

  void _onUserName(OnboardingUserNameChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(userName: event.value));
  }

  void _onBusinessName(OnboardingBusinessNameChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(businessName: event.value));
  }

  void _onCurrency(OnboardingCurrencyChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(currency: event.value));
  }

  void _onTaxId(OnboardingTaxIdChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(taxId: event.value));
  }

  void _onTerms(OnboardingPaymentTermsChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(paymentTerms: event.value));
  }

  void _onTheme(OnboardingThemeChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(themeModeName: event.value));
  }

  Future<void> _onCompleted(OnboardingCompleted event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(status: OnboardingStatus.saving));

    final profile = BusinessProfile(
      businessName: state.businessName.trim().isEmpty ? 'My Business' : state.businessName.trim(),
      ownerName: state.userName.trim().isEmpty ? null : state.userName.trim(),
      defaultCurrency: state.currency,
      taxId: state.taxId.trim().isEmpty ? null : state.taxId.trim(),
      defaultPaymentTerms: state.paymentTerms.trim().isEmpty
          ? 'Payment due within 14 days.'
          : state.paymentTerms.trim(),
      selectedPdfTemplate: 'classic',
    );
    await businessRepo.save(profile);

    final settings = AppSettings(
      currency: state.currency,
      themeModeName: state.themeModeName,
    );
    await settingsRepo.save(settings);

    // Start the trial automatically when onboarding completes.
    final current = await subscriptionRepo.current();
    if (entitlements.canStartTrial(current)) {
      await subscriptionRepo.save(entitlements.startTrial(current, DateTime.now()));
    }

    await localStorage.setBool(StorageKeys.onboardingCompleted, true);

    emit(state.copyWith(status: OnboardingStatus.completed));
  }
}
