import 'package:invoice_kit/features/premium/domain/entities/premium_access_decision.dart';

/// Read-only view over premium state. The repository hides whether the
/// decision is sourced from cache, subscription bloc, or a fresh fetch.
abstract class PremiumRepository {
  Future<PremiumAccessDecision> currentDecision();

  /// Stream of decisions — emits whenever the underlying subscription or
  /// auth state changes.
  Stream<PremiumAccessDecision> watch();
}
