import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/premium/domain/entities/premium_access_decision.dart';
import 'package:invoice_kit/features/premium/domain/repositories/premium_repository.dart';

part 'premium_state.dart';

/// Cubit around [PremiumRepository] — exposes the cached decision and
/// lets the UI ask for a re-evaluation (e.g. after a successful purchase).
class PremiumCubit extends Cubit<PremiumState> {
  PremiumCubit({required PremiumRepository repository})
    : _repository = repository,
      super(const PremiumState._()) {
    _subscription = repository.watch().listen(_onDecision);
  }

  final PremiumRepository _repository;
  late final StreamSubscription<PremiumAccessDecision> _subscription;

  Future<void> refresh() async {
    emit(state.copyWith(status: PremiumStatus.loading));
    final decision = await _repository.currentDecision();
    emit(
      state.copyWith(
        status: PremiumStatus.ready,
        decision: decision,
      ),
    );
  }

  void _onDecision(PremiumAccessDecision decision) {
    emit(state.copyWith(status: PremiumStatus.ready, decision: decision));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
