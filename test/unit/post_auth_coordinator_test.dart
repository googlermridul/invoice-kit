import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_kit/app/app_config.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/logger/logger.dart';
import 'package:invoice_kit/features/authentication/domain/entities/user.dart';
import 'package:invoice_kit/features/authentication/presentation/coordinators/post_auth_coordinator.dart';
import 'package:invoice_kit/features/devices/domain/entities/device.dart';
import 'package:invoice_kit/features/devices/domain/usecases/enforce_device_limit_usecase.dart';
import 'package:invoice_kit/features/devices/domain/usecases/register_device_usecase.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_access_manager.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_checker.dart';
import 'package:invoice_kit/features/premium/presentation/bloc/premium_cubit.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockRegisterDevice extends Mock implements RegisterDeviceUseCase {}

class _MockEnforceDeviceLimit extends Mock implements EnforceDeviceLimitUseCase {}

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

class _MockSubscriptionBloc extends Mock implements SubscriptionBloc {}

class _MockPremiumCubit extends Mock implements PremiumCubit {}

class _FakeSubscriptionBlocState extends Fake implements SubscriptionBlocState {}

class _FakeSubscriptionEvent extends Fake implements SubscriptionEvent {}

const _testConfig = AppConfig(
  environment: 'test',
  appName: 'InvoiceKit Test',
  apiBaseUrl: '',
  supabaseUrl: '',
  supabasePublishableKey: '',
  apiTimeoutSeconds: 30,
  enableLogging: false,
  enableSslPinning: false,
  locale: 'en',
  googleWebClientId: '',
  googleIosClientId: '',
  playBillingMonthlyProductId: '',
  playBillingYearlyProductId: '',
  playBillingBasePlanId: '',
  maxDevicesPerAccount: 3,
);

final CoreLogger _noopLogger = CoreLogger(enabled: false);

PostAuthCoordinator _build({
  required RegisterDeviceUseCase registerDevice,
  required EnforceDeviceLimitUseCase enforceDeviceLimit,
  required SubscriptionRepository subscriptionRepository,
  SubscriptionBloc? subscriptionBloc,
  PremiumCubit? premiumCubit,
}) {
  return PostAuthCoordinator(
    registerDevice: registerDevice,
    enforceDeviceLimit: enforceDeviceLimit,
    subscriptionRepository: subscriptionRepository,
    premiumManager: const PremiumAccessManager(PremiumChecker()),
    subscriptionBloc: subscriptionBloc,
    premiumCubit: premiumCubit,
    config: _testConfig,
    logger: _noopLogger,
  );
}

Device _device(String id) => Device(
  id: id,
  userId: 'u1',
  deviceId: 'd-$id',
  deviceName: 'Device $id',
  platform: 'android',
  lastSeenAt: DateTime.now(),
  createdAt: DateTime.now(),
);

const _user = User(id: 'u1', email: 'a@b.com');

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSubscriptionBlocState());
    registerFallbackValue(_FakeSubscriptionEvent());
    registerFallbackValue(DateTime(2026));
    if (!sl.isRegistered<AppConfig>()) {
      sl.registerSingleton<AppConfig>(_testConfig);
    }
  });

  tearDownAll(() async {
    if (sl.isRegistered<AppConfig>()) {
      await sl.unregister<AppConfig>();
    }
  });

  test('active subscription → dashboard', () async {
    final register = _MockRegisterDevice();
    final enforce = _MockEnforceDeviceLimit();
    final repo = _MockSubscriptionRepository();
    final bloc = _MockSubscriptionBloc();
    final premium = _MockPremiumCubit();

    when(
      () => register.call(
        userId: any(named: 'userId'),
        deviceId: any(named: 'deviceId'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async => _device('0'));
    when(
      () => enforce.call(
        userId: any(named: 'userId'),
        maxDevices: any(named: 'maxDevices'),
      ),
    ).thenAnswer((_) async => true);
    final now = DateTime.now();
    when(repo.refresh).thenAnswer(
      (_) async => SubscriptionStatus(
        state: SubscriptionState.active,
        currentPeriodEnd: now.add(const Duration(days: 30)),
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.state).thenReturn(_FakeSubscriptionBlocState());
    when(() => bloc.add(any())).thenReturn(null);
    when(premium.refresh).thenAnswer((_) async {});

    final coordinator = _build(
      registerDevice: register,
      enforceDeviceLimit: enforce,
      subscriptionRepository: repo,
      subscriptionBloc: bloc,
      premiumCubit: premium,
    );

    final result = await coordinator.run(
      user: _user,
      deviceId: 'd-1',
      deviceName: 'Pixel 8',
      platform: 'android',
      now: now,
    );

    expect(result.route, PostAuthRoute.dashboard);
    expect(result.reason, 'active-subscription');
    verify(() => bloc.add(any(that: isA<SubscriptionStarted>()))).called(1);
    verify(premium.refresh).called(1);
  });

  test('device limit exceeded → /devices', () async {
    final register = _MockRegisterDevice();
    final enforce = _MockEnforceDeviceLimit();
    final repo = _MockSubscriptionRepository();

    when(
      () => register.call(
        userId: any(named: 'userId'),
        deviceId: any(named: 'deviceId'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async => _device('0'));
    when(
      () => enforce.call(
        userId: any(named: 'userId'),
        maxDevices: any(named: 'maxDevices'),
      ),
    ).thenAnswer((_) async => false);
    when(repo.refresh).thenAnswer(
      (_) async => const SubscriptionStatus(state: SubscriptionState.expired),
    );

    final coordinator = _build(
      registerDevice: register,
      enforceDeviceLimit: enforce,
      subscriptionRepository: repo,
    );

    final result = await coordinator.run(
      user: _user,
      deviceId: 'd-1',
      deviceName: 'Pixel 8',
      platform: 'android',
    );

    expect(result.route, PostAuthRoute.devices);
    expect(result.reason, 'device-limit-exceeded');
    verifyNever(repo.refresh);
  });

  test('no active subscription → /subscription', () async {
    final register = _MockRegisterDevice();
    final enforce = _MockEnforceDeviceLimit();
    final repo = _MockSubscriptionRepository();

    when(
      () => register.call(
        userId: any(named: 'userId'),
        deviceId: any(named: 'deviceId'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async => _device('0'));
    when(
      () => enforce.call(
        userId: any(named: 'userId'),
        maxDevices: any(named: 'maxDevices'),
      ),
    ).thenAnswer((_) async => true);
    when(repo.refresh).thenAnswer(
      (_) async => const SubscriptionStatus(state: SubscriptionState.expired),
    );

    final coordinator = _build(
      registerDevice: register,
      enforceDeviceLimit: enforce,
      subscriptionRepository: repo,
    );

    final result = await coordinator.run(
      user: _user,
      deviceId: 'd-1',
      deviceName: 'Pixel 8',
      platform: 'android',
    );

    expect(result.route, PostAuthRoute.subscription);
    expect(result.reason, 'no-active-subscription');
  });
}
