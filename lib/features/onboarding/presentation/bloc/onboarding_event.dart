part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => const [];
}

class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted();
}

class OnboardingStepChanged extends OnboardingEvent {
  const OnboardingStepChanged(this.step);
  final int step;
  @override
  List<Object?> get props => [step];
}

class OnboardingUserNameChanged extends OnboardingEvent {
  const OnboardingUserNameChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class OnboardingBusinessNameChanged extends OnboardingEvent {
  const OnboardingBusinessNameChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class OnboardingCurrencyChanged extends OnboardingEvent {
  const OnboardingCurrencyChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class OnboardingTaxIdChanged extends OnboardingEvent {
  const OnboardingTaxIdChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class OnboardingPaymentTermsChanged extends OnboardingEvent {
  const OnboardingPaymentTermsChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class OnboardingThemeChanged extends OnboardingEvent {
  const OnboardingThemeChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}
