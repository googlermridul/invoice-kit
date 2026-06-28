import 'package:flutter/foundation.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/features/premium/presentation/bloc/premium_cubit.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';

/// Side-effects that should run after a successful sign-out.
///
/// Goals:
///   * Force the subscription cache to its initial state (no active
///     subscription) so the next render of paywalled UI does not briefly
///     flash a stale "premium" state.
///   * Refresh the [PremiumCubit] so the router guard and any
///     `BlocBuilder`s re-evaluate access immediately.
///   * **Preserve** the local trial window — the spec says trial state
///     is intentionally left intact so the user can still see "N days
///     left" on the next anonymous launch.
///
/// Pure: returns when all effects have completed. Callers can
/// `await LogoutSideEffects.run()` before navigating away.
class LogoutSideEffects {
  LogoutSideEffects({
    SubscriptionRepository? subscriptionRepository,
    SubscriptionBloc? subscriptionBloc,
    PremiumCubit? premiumCubit,
    TrialRepository? trialRepository,
  }) : _subscription = subscriptionRepository ?? sl<SubscriptionRepository>(),
       _subscriptionBloc = subscriptionBloc,
       _premiumCubit = premiumCubit,
       _trialRepository = trialRepository ?? sl<TrialRepository>();

  final SubscriptionRepository _subscription;
  final SubscriptionBloc? _subscriptionBloc;
  final PremiumCubit? _premiumCubit;
  // Kept for API symmetry; the trial repository is intentionally
  // not mutated by sign-out.
  // ignore: unused_field
  final TrialRepository? _trialRepository;

  Future<void> run() async {
    try {
      await _subscription.clear();
    } on Object catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('LogoutSideEffects: subscription.clear() failed: $e\n$st');
      }
    }

    // Tell the subscription bloc to re-read from the repository so the
    // status stream emits the cleared state.
    _subscriptionBloc?.add(const SubscriptionStarted());

    // Re-evaluate the premium access manager so the router guard's
    // `premium-denied` outcome is observed.
    await _premiumCubit?.refresh();
  }
}
