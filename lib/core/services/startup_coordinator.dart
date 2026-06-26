import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';
import 'package:invoice_kit/features/devices/domain/repositories/device_repository.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_access_manager.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_context.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';

/// Where the startup coordinator decides to send the user.
enum StartupDestination {
  home,
  onboarding,
  trialExpired,
  auth,
  subscription,
  deviceManagement,
}

class StartupDecision {
  const StartupDecision({
    required this.destination,
    this.reason,
  });

  final StartupDestination destination;

  /// Optional human-readable reason for logging / analytics.
  final String? reason;

  String get routePath => switch (destination) {
    StartupDestination.home => RoutePaths.dashboard,
    StartupDestination.onboarding => RoutePaths.onboarding,
    StartupDestination.trialExpired => RoutePaths.trialExpired,
    StartupDestination.auth => RoutePaths.login,
    StartupDestination.subscription => RoutePaths.subscription,
    StartupDestination.deviceManagement => RoutePaths.devices,
  };
}

/// Runs at app launch and decides where to send the user. The order is
/// documented in the project's brief:
///
///   1. Restore auth session.
///   2. Check local trial status.
///   3. Check subscription status if logged in.
///   4. Sync device status if logged in.
///   5. Initialize premium state.
///   6. Navigate per priority.
class StartupCoordinator {
  StartupCoordinator({
    required TrialRepository trialRepository,
    required SubscriptionRepository subscriptionRepository,
    required AuthRepository authRepository,
    required DeviceRepository deviceRepository,
    required PremiumAccessManager premiumManager,
    required this.maxDevices,
    required this.onboardingCompleted,
  }) : _trial = trialRepository,
       _subscription = subscriptionRepository,
       _auth = authRepository,
       _devices = deviceRepository,
       _manager = premiumManager;

  final TrialRepository _trial;
  final SubscriptionRepository _subscription;
  final AuthRepository _auth;
  final DeviceRepository _devices;
  final PremiumAccessManager _manager;
  final int maxDevices;
  final bool onboardingCompleted;

  /// Run the full startup pipeline. Returns the destination the router
  /// should navigate to.
  Future<StartupDecision> run({DateTime? now}) async {
    if (!onboardingCompleted) {
      return const StartupDecision(
        destination: StartupDestination.onboarding,
        reason: 'onboarding incomplete',
      );
    }

    // 1. Restore auth session.
    final session = await _auth.restoreSession();
    final isAuthenticated = session != null;

    // 2. Local trial status.
    final trial = await _trial.currentTrial();

    // 3. Subscription status (always safe to read — falls back to
    //    cached local state if remote is unreachable).
    final status = await _subscription.current();

    // 4. Device sync if logged in.
    var deviceCount = 0;
    if (isAuthenticated) {
      try {
        final list = await _devices.fetchDevices(userId: session.user.id);
        deviceCount = list.length;
      } on Object catch (_) {
        // Best-effort — fall through to local decision.
      }
    }

    // 5+6. Centralised decision via the premium access manager.
    final context = PremiumContext(
      status: status,
      isAuthenticated: isAuthenticated,
      deviceCount: deviceCount,
      maxDevices: maxDevices,
      now: now ?? DateTime.now(),
    );
    final outcome = _manager.resolve(context);

    if (outcome.redirect == PremiumRedirect.toDeviceManagement) {
      return const StartupDecision(
        destination: StartupDestination.deviceManagement,
        reason: 'device limit exceeded',
      );
    }
    if (outcome.isGranted) {
      return const StartupDecision(
        destination: StartupDestination.home,
        reason: 'premium access granted',
      );
    }
    if (trial != null && trial.isActive(context.effectiveNow())) {
      // Trial still active — go home regardless of the manager decision
      // (which may have read stale state).
      return const StartupDecision(
        destination: StartupDestination.home,
        reason: 'active trial',
      );
    }
    if (!isAuthenticated) {
      // Trial expired + not logged in.
      return const StartupDecision(
        destination: StartupDestination.trialExpired,
        reason: 'expired trial, not authenticated',
      );
    }
    // Logged in but no active subscription.
    return const StartupDecision(
      destination: StartupDestination.subscription,
      reason: 'no active subscription',
    );
  }
}
