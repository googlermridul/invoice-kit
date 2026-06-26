import 'package:invoice_kit/features/trial/domain/entities/trial_state.dart';

/// Local-only contract for the trial window. The trial is intentionally
/// decoupled from subscription: no Supabase call is made for starting or
/// ending it.
abstract class TrialRepository {
  /// Returns the active trial if one was ever started.
  Future<TrialState?> currentTrial();

  /// Returns true if a trial was started and is still inside its window.
  Future<bool> isActive({DateTime? now});

  /// Returns whole days remaining (clamped to 0). Reads from cache only.
  Future<int> daysRemaining({DateTime? now});

  /// Persist a new 7-day trial window. Idempotent — calling again while
  /// the existing trial is still active is a no-op.
  Future<TrialState> startTrial({required DateTime now});

  /// Forcibly end the trial without starting a subscription. Mostly used by
  /// tests or when the user explicitly opts out before the window ends.
  Future<void> expireTrial();

  /// Wipe all trial data — used by the sign-out / delete-account flow.
  Future<void> clear();
}
