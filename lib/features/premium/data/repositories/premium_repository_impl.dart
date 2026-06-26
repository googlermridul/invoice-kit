import 'dart:async';

import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';
import 'package:invoice_kit/features/premium/domain/entities/premium_access_decision.dart';
import 'package:invoice_kit/features/premium/domain/repositories/premium_repository.dart';
import 'package:invoice_kit/features/premium/domain/services/premium_checker.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';

/// Aggregates subscription status and auth state into a single
/// [PremiumAccessDecision] stream.
class PremiumRepositoryImpl implements PremiumRepository {
  PremiumRepositoryImpl({
    required SubscriptionRepository subscriptionRepository,
    required AuthRepository authRepository,
    PremiumChecker? checker,
  }) : _subscription = subscriptionRepository,
       _auth = authRepository,
       _checker = checker ?? const PremiumChecker() {
    _refreshController = StreamController<PremiumAccessDecision>.broadcast();
    _subscription.watch().listen(_emitFromStatus);
    _evaluate();
  }

  final SubscriptionRepository _subscription;
  final AuthRepository _auth;
  final PremiumChecker _checker;

  late final StreamController<PremiumAccessDecision> _refreshController;
  PremiumAccessDecision _last = const PremiumAccessDecision(
    result: PremiumAccessResult.deniedNoTrial,
  );

  PremiumAccessDecision get _lastOrEmpty => _last;

  void _emitFromStatus(SubscriptionStatus _) => _evaluate();

  Future<void> _evaluate() async {
    try {
      final status = await _subscription.current();
      final authenticated = await _auth.isAuthenticated();
      _last = _checker.evaluate(
        status: status,
        now: DateTime.now(),
        isAuthenticated: authenticated,
      );
      _refreshController.add(_last);
    } on Object catch (_) {
      // Swallow — keep last decision. Premium is best-effort.
    }
  }

  @override
  Future<PremiumAccessDecision> currentDecision() async {
    await _evaluate();
    return _lastOrEmpty;
  }

  @override
  Stream<PremiumAccessDecision> watch() => _refreshController.stream;
}
