import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/app/app_config.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/logger/logger.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';
import 'package:invoice_kit/features/devices/domain/repositories/device_repository.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_access_manager.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_context.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart'
    show SubscriptionStatus;
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';

/// Decides where to redirect the user based on the current state of:
///  - onboarding completion
///  - subscription / trial entitlement
///  - device limit
///  - premium access for the requested route
///
/// Premium access is decided at runtime against the persisted
/// [SubscriptionStatus] so that a free trial ending while the app is
/// backgrounded takes effect on the very next navigation.
class AppRouterGuard {
  AppRouterGuard({
    required this.subscriptionBloc,
    SubscriptionRepository? subscriptionRepository,
    LocalStorageService? localStorage,
    AuthRepository? authRepository,
    TrialRepository? trialRepository,
    DeviceRepository? deviceRepository,
    PremiumAccessManager? premiumManager,
    CoreLogger? logger,
  }) : subscriptionRepository =
           subscriptionRepository ?? sl<SubscriptionRepository>(),
       localStorage = localStorage ?? sl<LocalStorageService>(),
       _auth = authRepository ?? sl<AuthRepository>(),
       _trial = trialRepository ?? sl<TrialRepository>(),
       _devices = deviceRepository ?? sl<DeviceRepository>(),
       _manager = premiumManager ?? sl<PremiumAccessManager>(),
       _logger = logger ?? sl<CoreLogger>();

  final SubscriptionBloc subscriptionBloc;
  final SubscriptionRepository subscriptionRepository;
  final LocalStorageService localStorage;
  final AuthRepository _auth;
  final TrialRepository _trial;
  final DeviceRepository _devices;
  final PremiumAccessManager _manager;
  final CoreLogger _logger;

  /// Routes that are *always* publicly accessible regardless of
  /// authentication, trial, or subscription state. Auth / help / reset
  /// / paywall flows live here so that:
  ///  - `/register` is not redirected back to `/login`
  ///  - `/forgot-password` is not redirected to `/trial-expired`
  ///  - `/subscription` works for logged-in users without an active plan
  ///  - `/devices` works even when device count is exceeded (so the user
  ///    can manage their own devices)
  static const Set<String> publicRoutes = {
    RoutePaths.splash,
    RoutePaths.onboarding,
    RoutePaths.login,
    RoutePaths.register,
    RoutePaths.forgotPassword,
    RoutePaths.subscription,
    RoutePaths.trialExpired,
    RoutePaths.devices,
  };

  /// Routes that are only meaningful during onboarding and are gated
  /// separately from the auth/subscription flow.
  static const Set<String> onboardingOnlyRoutes = {
    RoutePaths.splash,
    RoutePaths.onboarding,
  };

  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    return resolveForLocation(state.matchedLocation);
  }

  /// Returns the redirect target for [location], or `null` to allow it.
  ///
  /// Extracted from [redirect] so unit tests can drive the decision logic
  /// without constructing a `GoRouterState` (which requires private
  /// library types).
  Future<String?> resolveForLocation(String location) async {
    // ── 1. Onboarding gate ──────────────────────────────────────────────
    final completed =
        localStorage.getBool(StorageKeys.onboardingCompleted) ?? false;
    if (!completed) {
      if (onboardingOnlyRoutes.contains(location)) {
        _logRedirect('allow', location, 'onboarding-allowed');
        return null;
      }
      _logRedirect(RoutePaths.onboarding, location, 'onboarding-not-completed');
      return RoutePaths.onboarding;
    }

    // ── 2. Public-route gate ────────────────────────────────────────────
    // Auth / help / reset / paywall flows must always render so users can
    // recover from a bad state (expired trial, locked out, etc).
    if (publicRoutes.contains(location)) {
      _logRedirect('allow', location, 'public-route');
      return null;
    }

    // ── 3. Evaluate access / device context ────────────────────────────
    final persisted = await subscriptionRepository.current();
    final now = DateTime.now();
    final hasAccess = persisted.hasAccess(now);

    final trial = await _trial.currentTrial();
    final trialActive = trial != null && trial.isActive(now);

    final session = await _auth.restoreSession();
    final isAuthenticated = session != null;
    var deviceCount = 0;
    if (isAuthenticated) {
      try {
        final list = await _devices.fetchDevices(userId: session.user.id);
        deviceCount = list.length;
      } on Object catch (e, st) {
        _logger.raw.w(
          'Failed to fetch devices for redirect decision: $e\n$st',
        );
      }
    }

    final ctx = PremiumContext(
      status: persisted,
      isAuthenticated: isAuthenticated,
      deviceCount: deviceCount,
      maxDevices: sl<AppConfig>().maxDevicesPerAccount,
      now: now,
    );

    // ── 4. Device limit gate ────────────────────────────────────────────
    final deviceOutcome = _manager.resolve(ctx);
    if (deviceOutcome.redirect == PremiumRedirect.toDeviceManagement) {
      _logRedirect(RoutePaths.devices, location, 'device-limit-exceeded');
      return _redirect(RoutePaths.devices, location);
    }

    // ── 5. No-access gate (expired trial / no subscription) ─────────────
    if (!hasAccess && !trialActive) {
      final target = isAuthenticated
          ? RoutePaths.subscription
          : RoutePaths.login;
      _logRedirect(target, location, 'no-active-entitlement');
      return _redirect(target, location);
    }

    // ── 6. Premium enforcement for protected app routes ─────────────────
    final premiumTarget = _enforcePremium(location, ctx);
    if (premiumTarget != null) {
      _logRedirect(premiumTarget, location, 'premium-denied');
      return premiumTarget;
    }

    _logRedirect('allow', location, 'granted');
    return null;
  }

  String? _enforcePremium(String location, PremiumContext context) {
    final result = _manager.resolve(context);
    if (result.isGranted) return null;
    return _redirect(
      switch (result.redirect) {
        PremiumRedirect.toAuth => RoutePaths.login,
        PremiumRedirect.toSubscription => RoutePaths.subscription,
        PremiumRedirect.toDeviceManagement => RoutePaths.devices,
        PremiumRedirect.none => RoutePaths.dashboard,
      },
      location,
    );
  }

  String? _redirect(String target, String current) {
    if (target == current) return null;
    return target;
  }

  void _logRedirect(String target, String from, String reason) {
    if (!kDebugMode) return;
    final line = 'AppRouterGuard $from -> $target (reason=$reason)';
    _logger.raw.d(line);
  }
}
