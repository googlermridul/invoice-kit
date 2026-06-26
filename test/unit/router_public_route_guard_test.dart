// import 'package:flutter_test/flutter_test.dart';
// import 'package:invoice_kit/app/app_config.dart';
// import 'package:invoice_kit/core/di/injection.dart';
// import 'package:invoice_kit/core/logger/logger.dart';
// import 'package:invoice_kit/core/router/app_router_guard.dart';
// import 'package:invoice_kit/core/router/route_paths.dart';
// import 'package:invoice_kit/core/storage/local_storage_service.dart';
// import 'package:invoice_kit/features/authentication/domain/entities/user.dart';
// import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';
// import 'package:invoice_kit/features/devices/domain/entities/device.dart';
// import 'package:invoice_kit/features/devices/domain/repositories/device_repository.dart';
// import 'package:invoice_kit/features/premium/domain/services/premium_access_manager.dart';
// import 'package:invoice_kit/features/premium/domain/services/premium_checker.dart';
// import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
// import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';
// import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
// import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';
// import 'package:mocktail/mocktail.dart';

// class _MockLocalStorage extends Mock implements LocalStorageService {}

// class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

// class _MockTrialRepository extends Mock implements TrialRepository {}

// class _MockAuthRepository extends Mock implements AuthRepository {}

// class _MockDeviceRepository extends Mock implements DeviceRepository {}

// class _MockSubscriptionBloc extends Mock implements SubscriptionBloc {}

// /// Local no-op logger to satisfy the guard's optional dependency.
// final CoreLogger _noopLogger = CoreLogger(enabled: false);

// AppRouterGuard _buildGuard({
//   required LocalStorageService localStorage,
//   required SubscriptionRepository subscriptionRepo,
//   required TrialRepository trialRepo,
//   required AuthRepository authRepo,
//   required DeviceRepository deviceRepo,
// }) {
//   return AppRouterGuard(
//     subscriptionBloc: _MockSubscriptionBloc(),
//     subscriptionRepository: subscriptionRepo,
//     localStorage: localStorage,
//     authRepository: authRepo,
//     trialRepository: trialRepo,
//     deviceRepository: deviceRepo,
//     premiumManager: PremiumAccessManager(const PremiumChecker()),
//     logger: _noopLogger,
//   );
// }

// SubscriptionStatus _expiredStatus() => const SubscriptionStatus(state: SubscriptionState.expired);

// SubscriptionStatus _activePaidStatus(DateTime now) => SubscriptionStatus(
//   state: SubscriptionState.active,
//   currentPeriodEnd: now.add(const Duration(days: 30)),
// );

// Device _device(String id) => Device(
//   id: id,
//   userId: 'u1',
//   deviceId: 'd-$id',
//   deviceName: 'Device $id',
//   platform: 'android',
//   lastSeenAt: DateTime.now(),
//   createdAt: DateTime.now(),
// );

// void main() {
//   setUpAll(() {
//     // The guard pulls `AppConfig` from GetIt to compute `maxDevicesPerAccount`.
//     // Register a minimal stub once for all tests in this file.
//     if (!sl.isRegistered<AppConfig>()) {
//       sl.registerSingleton<AppConfig>(
//         AppConfig(
//           environment: 'test',
//           appName: 'InvoiceKit Test',
//           apiBaseUrl: '',
//           supabaseUrl: '',
//           supabasePublishableKey: '',
//           apiTimeoutSeconds: 30,
//           enableLogging: false,
//           enableSslPinning: false,
//           locale: 'en',
//           googleWebClientId: '',
//           googleIosClientId: '',
//           playBillingMonthlyProductId: '',
//           playBillingYearlyProductId: '',
//           playBillingBasePlanId: '',
//           maxDevicesPerAccount: 3,
//         ),
//       );
//     }
//   });

//   tearDownAll(() async {
//     if (sl.isRegistered<AppConfig>()) {
//       await sl.unregister<AppConfig>();
//     }
//   });
//   group('AppRouterGuard public-route gate', () {
//     final localStorage = _MockLocalStorage();
//     final subscriptionRepo = _MockSubscriptionRepository();
//     final trialRepo = _MockTrialRepository();
//     final authRepo = _MockAuthRepository();
//     final deviceRepo = _MockDeviceRepository();

//     setUp(() {
//       when(() => localStorage.getBool(any())).thenReturn(true);
//       when(subscriptionRepo.current).thenAnswer(
//         (_) async => _expiredStatus(),
//       );
//       when(trialRepo.currentTrial).thenAnswer((_) async => null);
//       when(authRepo.restoreSession).thenAnswer((_) async => null);
//       when(
//         () => deviceRepo.fetchDevices(userId: any(named: 'userId')),
//       ).thenAnswer((_) async => const <Device>[]);
//     });

//     test('expired trial can open /login', () async {
//       final guard = _buildGuard(
//         localStorage: localStorage,
//         subscriptionRepo: subscriptionRepo,
//         trialRepo: trialRepo,
//         authRepo: authRepo,
//         deviceRepo: deviceRepo,
//       );
//       expect(await guard.resolveForLocation(RoutePaths.login), isNull);
//     });

//     test('expired trial can open /register', () async {
//       final guard = _buildGuard(
//         localStorage: localStorage,
//         subscriptionRepo: subscriptionRepo,
//         trialRepo: trialRepo,
//         authRepo: authRepo,
//         deviceRepo: deviceRepo,
//       );
//       expect(await guard.resolveForLocation(RoutePaths.register), isNull);
//     });

//     test('expired trial can open /forgot-password', () async {
//       final guard = _buildGuard(
//         localStorage: localStorage,
//         subscriptionRepo: subscriptionRepo,
//         trialRepo: trialRepo,
//         authRepo: authRepo,
//         deviceRepo: deviceRepo,
//       );
//       expect(
//         await guard.resolveForLocation(RoutePaths.forgotPassword),
//         isNull,
//       );
//     });

//     test('expired trial can open /trial-expired', () async {
//       final guard = _buildGuard(
//         localStorage: localStorage,
//         subscriptionRepo: subscriptionRepo,
//         trialRepo: trialRepo,
//         authRepo: authRepo,
//         deviceRepo: deviceRepo,
//       );
//       expect(
//         await guard.resolveForLocation(RoutePaths.trialExpired),
//         isNull,
//       );
//     });

//     test('expired trial can open /subscription', () async {
//       final guard = _buildGuard(
//         localStorage: localStorage,
//         subscriptionRepo: subscriptionRepo,
//         trialRepo: trialRepo,
//         authRepo: authRepo,
//         deviceRepo: deviceRepo,
//       );
//       expect(
//         await guard.resolveForLocation(RoutePaths.subscription),
//         isNull,
//       );
//     });

//     test('protected app route redirects to /login after expired trial '
//         'for unauthenticated user', () async {
//       final guard = _buildGuard(
//         localStorage: localStorage,
//         subscriptionRepo: subscriptionRepo,
//         trialRepo: trialRepo,
//         authRepo: authRepo,
//         deviceRepo: deviceRepo,
//       );
//       expect(
//         await guard.resolveForLocation(RoutePaths.dashboard),
//         RoutePaths.login,
//       );
//     });

//     test('protected app route redirects to /subscription when logged-in '
//         'user has no entitlement', () async {
//       final session = AuthSession(
//         accessToken: 'tok',
//         refreshToken: '',
//         user: const User(id: 'u1', email: 'a@b.com'),
//       );
//       when(authRepo.restoreSession).thenAnswer((_) async => session);
//       when(
//         () => deviceRepo.fetchDevices(userId: 'u1'),
//       ).thenAnswer((_) async => const <Device>[]);

//       final guard = _buildGuard(
//         localStorage: localStorage,
//         subscriptionRepo: subscriptionRepo,
//         trialRepo: trialRepo,
//         authRepo: authRepo,
//         deviceRepo: deviceRepo,
//       );
//       expect(
//         await guard.resolveForLocation(RoutePaths.dashboard),
//         RoutePaths.subscription,
//       );
//     });

//     test(
//       'protected app route is allowed when active subscription exists',
//       () async {
//         when(subscriptionRepo.current).thenAnswer(
//           (_) async => _activePaidStatus(DateTime.now()),
//         );
//         final guard = _buildGuard(
//           localStorage: localStorage,
//           subscriptionRepo: subscriptionRepo,
//           trialRepo: trialRepo,
//           authRepo: authRepo,
//           deviceRepo: deviceRepo,
//         );
//         expect(await guard.resolveForLocation(RoutePaths.dashboard), isNull);
//       },
//     );

//     test('public-route set always includes auth/help/paywall routes', () {
//       // Regression guard: if anyone removes a route from
//       // AppRouterGuard.publicRoutes these assertions catch it before the
//       // bug ships.
//       expect(AppRouterGuard.publicRoutes, contains(RoutePaths.login));
//       expect(AppRouterGuard.publicRoutes, contains(RoutePaths.register));
//       expect(AppRouterGuard.publicRoutes, contains(RoutePaths.forgotPassword));
//       expect(AppRouterGuard.publicRoutes, contains(RoutePaths.subscription));
//       expect(AppRouterGuard.publicRoutes, contains(RoutePaths.trialExpired));
//       expect(AppRouterGuard.publicRoutes, contains(RoutePaths.devices));
//       expect(AppRouterGuard.publicRoutes, contains(RoutePaths.onboarding));
//       expect(AppRouterGuard.publicRoutes, contains(RoutePaths.splash));
//     });
//   });

//   group('AppRouterGuard device-limit gate', () {
//     test('device limit exceeded redirects to /devices', () async {
//       final localStorage = _MockLocalStorage();
//       final subscriptionRepo = _MockSubscriptionRepository();
//       final trialRepo = _MockTrialRepository();
//       final authRepo = _MockAuthRepository();
//       final deviceRepo = _MockDeviceRepository();

//       when(() => localStorage.getBool(any())).thenReturn(true);
//       when(subscriptionRepo.current).thenAnswer(
//         (_) async => _activePaidStatus(DateTime.now()),
//       );
//       when(trialRepo.currentTrial).thenAnswer((_) async => null);
//       final session = AuthSession(
//         accessToken: 'tok',
//         refreshToken: '',
//         user: const User(id: 'u1', email: 'a@b.com'),
//       );
//       when(authRepo.restoreSession).thenAnswer((_) async => session);
//       // 5 devices > max of 3.
//       when(() => deviceRepo.fetchDevices(userId: 'u1')).thenAnswer(
//         (_) async => List<Device>.generate(5, (i) => _device('$i')),
//       );

//       final guard = _buildGuard(
//         localStorage: localStorage,
//         subscriptionRepo: subscriptionRepo,
//         trialRepo: trialRepo,
//         authRepo: authRepo,
//         deviceRepo: deviceRepo,
//       );
//       expect(
//         await guard.resolveForLocation(RoutePaths.dashboard),
//         RoutePaths.devices,
//       );
//       // /devices itself remains reachable so the user can manage.
//       expect(await guard.resolveForLocation(RoutePaths.devices), isNull);
//     });
//   });

//   group('AppRouterGuard onboarding gate', () {
//     test('not-completed onboarding routes everything to /onboarding', () async {
//       final localStorage = _MockLocalStorage();
//       final subscriptionRepo = _MockSubscriptionRepository();
//       final trialRepo = _MockTrialRepository();
//       final authRepo = _MockAuthRepository();
//       final deviceRepo = _MockDeviceRepository();

//       when(() => localStorage.getBool(any())).thenReturn(false);

//       final guard = _buildGuard(
//         localStorage: localStorage,
//         subscriptionRepo: subscriptionRepo,
//         trialRepo: trialRepo,
//         authRepo: authRepo,
//         deviceRepo: deviceRepo,
//       );
//       expect(
//         await guard.resolveForLocation(RoutePaths.dashboard),
//         RoutePaths.onboarding,
//       );
//       // /login is NOT in onboardingOnlyRoutes, so an un-boarded user
//       // is forced through /onboarding first.
//       expect(
//         await guard.resolveForLocation(RoutePaths.login),
//         RoutePaths.onboarding,
//       );
//       // /onboarding itself stays accessible.
//       expect(
//         await guard.resolveForLocation(RoutePaths.onboarding),
//         isNull,
//       );
//     });
//   });
// }
