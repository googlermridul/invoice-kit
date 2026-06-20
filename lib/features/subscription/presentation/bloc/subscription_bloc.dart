import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';
import 'package:invoice_kit/features/subscription/domain/services/entitlement_service.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({
    required this.repository,
    required this.entitlements,
  }) : super(SubscriptionState.initial()) {
    on<SubscriptionStarted>(_onStarted);
    on<SubscriptionRefreshed>(_onRefresh);
    on<SubscriptionPlanPurchased>(_onPurchased);
    on<SubscriptionRestored>(_onRestored);
    on<SubscriptionExpired>(_onExpired);
  }

  final SubscriptionRepository repository;
  final EntitlementService entitlements;

  Future<void> _onStarted(
    SubscriptionStarted event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatusX.loading));
    final current = await repository.current();
    emit(
      state.copyWith(
        status: SubscriptionStatusX.ready,
        subscriptionStatus: current,
        hasAccess: entitlements.hasAccess(current, DateTime.now()),
        trialDaysRemaining: entitlements.trialDaysRemaining(
          current,
          DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onRefresh(
    SubscriptionRefreshed event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatusX.refreshing));
    try {
      final remote = await repository.refresh();
      emit(
        state.copyWith(
          status: SubscriptionStatusX.ready,
          subscriptionStatus: remote,
          hasAccess: entitlements.hasAccess(remote, DateTime.now()),
          trialDaysRemaining: entitlements.trialDaysRemaining(
            remote,
            DateTime.now(),
          ),
        ),
      );
    } on Object catch (e) {
      emit(
        state.copyWith(
          status: SubscriptionStatusX.ready,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPurchased(
    SubscriptionPlanPurchased event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatusX.purchasing));
    final current = await repository.current();
    final updated = entitlements.activate(
      current: current,
      plan: event.plan,
      now: DateTime.now(),
    );
    await repository.save(updated);
    emit(
      state.copyWith(
        status: SubscriptionStatusX.ready,
        subscriptionStatus: updated,
        hasAccess: true,
        message: 'Subscription active',
      ),
    );
  }

  Future<void> _onRestored(
    SubscriptionRestored event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(status: SubscriptionStatusX.restoring));
    try {
      await repository.refresh();
      final current = await repository.current();
      emit(
        state.copyWith(
          status: SubscriptionStatusX.ready,
          subscriptionStatus: current,
          hasAccess: entitlements.hasAccess(current, DateTime.now()),
          message: current.isActive
              ? 'Subscription restored'
              : 'No subscription to restore',
        ),
      );
    } on Object catch (e) {
      emit(
        state.copyWith(
          status: SubscriptionStatusX.ready,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onExpired(
    SubscriptionExpired event,
    Emitter<SubscriptionState> emit,
  ) async {
    final current = await repository.current();
    final updated = entitlements.expire(current);
    await repository.save(updated);
    emit(
      state.copyWith(
        status: SubscriptionStatusX.ready,
        subscriptionStatus: updated,
        hasAccess: false,
      ),
    );
  }
}
