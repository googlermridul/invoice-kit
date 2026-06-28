import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/core/theme/app_theme.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:invoice_kit/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:invoice_kit/features/settings/data/repositories/settings_repository.dart';
import 'package:invoice_kit/features/settings/domain/entities/app_settings.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalStorage extends Mock implements LocalStorageService {}

class _MockSubscriptionBloc extends Mock implements SubscriptionBloc {}

class _MockBusinessProfileRepo extends Mock implements BusinessProfileRepository {}

class _MockSettingsRepo extends Mock implements SettingsRepository {}

class _FakeSubscriptionBlocState extends Fake implements SubscriptionBlocState {}

class _FakeSubscriptionEvent extends Fake implements SubscriptionEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSubscriptionBlocState());
    registerFallbackValue(_FakeSubscriptionEvent());
    registerFallbackValue(
      BusinessProfile(
        businessName: 'X',
        defaultCurrency: 'USD',
      ),
    );
    registerFallbackValue(AppSettings(currency: 'USD'));
  });

  testWidgets('Onboarding wizard renders the first step + Continue CTA', (
    tester,
  ) async {
    final local = _MockLocalStorage();
    final biz = _MockBusinessProfileRepo();
    final settings = _MockSettingsRepo();
    final subBloc = _MockSubscriptionBloc();

    when(() => local.getString(any())).thenReturn(null);
    when(biz.load).thenAnswer((_) async => null);
    when(settings.load).thenAnswer(
      (_) async => AppSettings(currency: 'USD'),
    );
    when(() => subBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => subBloc.state).thenReturn(_FakeSubscriptionBlocState());
    when(() => subBloc.add(any())).thenReturn(null);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider(
          create: (_) => OnboardingBloc(
            localStorage: local,
            businessRepo: biz,
            settingsRepo: settings,
            subscriptionBloc: subBloc,
          ),
          child: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
