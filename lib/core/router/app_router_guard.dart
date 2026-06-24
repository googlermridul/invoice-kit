import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';

/// Decides where to redirect the user based on the current state of:
///  - onboarding completion
///  - subscription / trial entitlement
///
/// Premium access is decided at runtime against the persisted
/// [SubscriptionStatus] so that a free trial ending while the app is
/// backgrounded takes effect on the very next navigation. This implements
/// the contract:
///
///   hasPremiumAccess = subscriptionActive || freeTrialActive
class AppRouterGuard {
  AppRouterGuard({
    required this.subscriptionBloc,
    SubscriptionRepository? subscriptionRepository,
    LocalStorageService? localStorage,
  }) : subscriptionRepository =
           subscriptionRepository ?? sl<SubscriptionRepository>(),
       localStorage = localStorage ?? sl<LocalStorageService>();

  final SubscriptionBloc subscriptionBloc;
  final SubscriptionRepository subscriptionRepository;
  final LocalStorageService localStorage;

  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final completed = localStorage.getBool(StorageKeys.onboardingCompleted) ?? false;
    if (!completed) {
      // Allow only the splash and onboarding routes.
      final allowed = {
        RoutePaths.splash,
        RoutePaths.onboarding,
      };
      return allowed.contains(state.matchedLocation) ? null : RoutePaths.onboarding;
    }

    // Re-evaluate access against the persisted status with the current
    // clock. Using the cached `subscriptionBloc.state.hasAccess` would be
    // stale during a trial: the bloc emits `hasAccess = true` once when
    // the trial starts and never re-reads the clock.
    final persisted = await subscriptionRepository.current();
    final hasAccess = persisted.hasAccess(DateTime.now());

    if (!hasAccess) {
      // After onboarding, skip forced subscription redirect and allow
      // dashboard access (and the subscription screen for upgrading).
      final allowed = {
        RoutePaths.splash,
        RoutePaths.dashboard,
        RoutePaths.subscription,
      };
      return allowed.contains(state.matchedLocation) ? null : RoutePaths.dashboard;
    }

    return null;
  }
}
