import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/features/authentication/presentation/coordinators/logout_side_effects.dart';
import 'package:invoice_kit/features/premium/presentation/bloc/premium_cubit.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:invoice_kit/features/trial/domain/entities/trial_state.dart';
import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

class _MockSubscriptionBloc extends Mock implements SubscriptionBloc {}

class _MockPremiumCubit extends Mock implements PremiumCubit {}

class _MockTrialRepository extends Mock implements TrialRepository {}

class _FakeSubscriptionBlocState extends Fake
    implements SubscriptionBlocState {}

class _FakeSubscriptionEvent extends Fake implements SubscriptionEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSubscriptionBlocState());
    registerFallbackValue(_FakeSubscriptionEvent());
  });

  test('clears subscription, refreshes premium, preserves trial', () async {
    final repo = _MockSubscriptionRepository();
    final bloc = _MockSubscriptionBloc();
    final premium = _MockPremiumCubit();
    final trial = _MockTrialRepository();

    when(() => repo.clear()).thenAnswer((_) async {});
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.state).thenReturn(_FakeSubscriptionBlocState());
    when(() => bloc.add(any())).thenReturn(null);
    when(() => premium.refresh()).thenAnswer((_) async {});

    // Trial repository must not be mutated.
    when(() => trial.clear()).thenAnswer((_) async {});
    final existingTrial = TrialState.fresh(DateTime(2026, 1, 1));
    when(() => trial.currentTrial()).thenAnswer((_) async => existingTrial);

    final effects = LogoutSideEffects(
      subscriptionRepository: repo,
      subscriptionBloc: bloc,
      premiumCubit: premium,
      trialRepository: trial,
    );

    await effects.run();

    verify(() => repo.clear()).called(1);
    verify(() => bloc.add(any(that: isA<SubscriptionStarted>()))).called(1);
    verify(() => premium.refresh()).called(1);
    // Trial is preserved — clear() is never invoked.
    verifyNever(() => trial.clear());
  });
}
