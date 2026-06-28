import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/core/theme/app_theme.dart';
import 'package:invoice_kit/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:invoice_kit/features/trial/domain/entities/trial_state.dart';
import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTrialRepository extends Mock implements TrialRepository {}

class _MockLocalStorage extends Mock implements LocalStorageService {}

class _MockSubscriptionBloc extends Mock implements SubscriptionBloc {}

class _FakeSubscriptionBlocState extends Fake
    implements SubscriptionBlocState {}

class _FakeSubscriptionEvent extends Fake implements SubscriptionEvent {}

GoRouter _routerFor({required WelcomeScreen welcome}) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (_, _) => welcome,
      ),
      GoRoute(path: '/login', builder: (_, _) => const _Placeholder()),
      GoRoute(path: '/onboarding', builder: (_, _) => const _Placeholder()),
    ],
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('placeholder')));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSubscriptionBlocState());
    registerFallbackValue(_FakeSubscriptionEvent());
  });

  testWidgets(
    'Login CTA marks intro done and does NOT start a trial',
    (tester) async {
      final trials = _MockTrialRepository();
      final storage = _MockLocalStorage();
      when(() => storage.setBool(any(), any())).thenAnswer((_) async => true);

      final bloc = _MockSubscriptionBloc();
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => bloc.state).thenReturn(_FakeSubscriptionBlocState());
      when(() => bloc.add(any())).thenReturn(null);

      final welcome = WelcomeScreen(
        trialRepository: trials,
        localStorage: storage,
        subscriptionBloc: bloc,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: _routerFor(welcome: welcome),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Already a premium user? Login'));
      await tester.pumpAndSettle();

      verify(
        () => storage.setBool(StorageKeys.introOnboardingCompleted, true),
      ).called(1);
      verifyNever(() => trials.startTrial(now: any(named: 'now')));
    },
  );

  testWidgets('Start-trial CTA writes trial_started_at and routes forward', (
    tester,
  ) async {
    final trials = _MockTrialRepository();
    final storage = _MockLocalStorage();
    final now = DateTime(2026, 1, 1, 12);
    final trial = TrialState.fresh(now);
    // The widget passes `DateTime.now()` — match that with `any(named: 'now')`.
    when(() => trials.startTrial(now: any(named: 'now'))).thenAnswer(
      (_) async => trial,
    );
    when(() => storage.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => storage.setString(any(), any())).thenAnswer((_) async => true);

    var addCount = 0;
    final bloc = _MockSubscriptionBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.state).thenReturn(_FakeSubscriptionBlocState());
    when(() => bloc.add(any())).thenAnswer((_) {
      addCount++;
    });

    final welcome = WelcomeScreen(
      trialRepository: trials,
      localStorage: storage,
      subscriptionBloc: bloc,
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: _routerFor(welcome: welcome),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    // Allow the async chain (mock Future + setState + context.go) to settle
    // on the real clock before verifying.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    verify(() => trials.startTrial(now: any(named: 'now'))).called(1);
    verify(
      () => storage.setString(StorageKeys.trialStartedAt, any()),
    ).called(1);
    verify(
      () => storage.setBool(StorageKeys.introOnboardingCompleted, true),
    ).called(1);
    expect(addCount, 1);
  });
}
