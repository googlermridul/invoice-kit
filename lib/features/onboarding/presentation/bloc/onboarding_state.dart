part of 'onboarding_bloc.dart';

enum OnboardingStatus { initial, loading, ready, saving, completed, failure }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.step = 0,
    this.userName = '',
    this.businessName = '',
    this.currency = 'USD',
    this.taxId = '',
    this.paymentTerms = 'Payment due within 3 days.',
    this.themeModeName = 'system',
    this.trialStartedAt,
    this.error,
  });

  factory OnboardingState.initial() => const OnboardingState();

  final OnboardingStatus status;
  final int step;
  final String userName;
  final String businessName;
  final String currency;
  final String taxId;
  final String paymentTerms;
  final String themeModeName;

  /// Mirror of [StorageKeys.trialStartedAt] so the setup wizard can show
  /// a "Trial · N days left" badge. Set only — the trial is started
  /// exclusively from the Welcome screen.
  final DateTime? trialStartedAt;

  final String? error;

  bool get canProceed => switch (step) {
    0 => true,
    1 => userName.trim().isNotEmpty,
    2 => businessName.trim().isNotEmpty,
    _ => true,
  };

  OnboardingState copyWith({
    OnboardingStatus? status,
    int? step,
    String? userName,
    String? businessName,
    String? currency,
    String? taxId,
    String? paymentTerms,
    String? themeModeName,
    DateTime? trialStartedAt,
    String? error,
    bool clearError = false,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      step: step ?? this.step,
      userName: userName ?? this.userName,
      businessName: businessName ?? this.businessName,
      currency: currency ?? this.currency,
      taxId: taxId ?? this.taxId,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      themeModeName: themeModeName ?? this.themeModeName,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    status,
    step,
    userName,
    businessName,
    currency,
    taxId,
    paymentTerms,
    themeModeName,
    trialStartedAt,
    error,
  ];
}
