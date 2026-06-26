import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';
import 'package:invoice_kit/features/subscription/domain/services/entitlement_service.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionBlocState> {
  SubscriptionBloc({
    required this.repository,
    required this.entitlements,
  }) : super(SubscriptionBlocState.initial()) {
    on<SubscriptionStarted>(_onStarted);
    on<SubscriptionRefreshed>(_onRefresh);
    on<SubscriptionPlanPurchased>(_onPurchased);
    on<SubscriptionRestored>(_onRestored);
    on<SubscriptionExpired>(_onExpired);
    on<SubscriptionTrialStarted>(_onTrialStarted);
    on<SubscriptionPurchasePending>(_onPurchasePending);
    on<SubscriptionGracePeriodEntered>(_onGracePeriod);
    on<SubscriptionCancelled>(_onCancelled);
    on<SubscriptionSyncedFromBackend>(_onSynced);
  }

  final SubscriptionRepository repository;
  final EntitlementService entitlements;

  Future<void> _onStarted(
    SubscriptionStarted event,
    Emitter<SubscriptionBlocState> emit,
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
    Emitter<SubscriptionBlocState> emit,
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
    Emitter<SubscriptionBlocState> emit,
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
    Emitter<SubscriptionBlocState> emit,
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
    Emitter<SubscriptionBlocState> emit,
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

  Future<void> _onTrialStarted(
    SubscriptionTrialStarted event,
    Emitter<SubscriptionBlocState> emit,
  ) async {
    await repository.save(event.status);
    final now = DateTime.now();
    emit(
      state.copyWith(
        status: SubscriptionStatusX.ready,
        subscriptionStatus: event.status,
        hasAccess: entitlements.hasAccess(event.status, now),
        trialDaysRemaining: entitlements.trialDaysRemaining(event.status, now),
        message: 'Trial started',
      ),
    );
  }

  Future<void> _onPurchasePending(
    SubscriptionPurchasePending event,
    Emitter<SubscriptionBlocState> emit,
  ) async {
    final current = await repository.current();
    final updated = current.copyWith(
      state: SubscriptionState.pending,
      productId: event.productId,
    );
    await repository.save(updated);
    emit(
      state.copyWith(
        status: SubscriptionStatusX.pending,
        subscriptionStatus: updated,
        hasAccess: false,
        message: 'Purchase pending — access will unlock once verified.',
      ),
    );
  }

  Future<void> _onGracePeriod(
    SubscriptionGracePeriodEntered event,
    Emitter<SubscriptionBlocState> emit,
  ) async {
    final current = await repository.current();
    final updated = current.copyWith(
      state: SubscriptionState.gracePeriod,
      currentPeriodEnd: event.expiryDate ?? current.currentPeriodEnd,
    );
    await repository.save(updated);
    emit(
      state.copyWith(
        status: SubscriptionStatusX.gracePeriod,
        subscriptionStatus: updated,
        hasAccess: true,
        message: 'Grace period — update your payment method to keep access.',
      ),
    );
  }

  Future<void> _onCancelled(
    SubscriptionCancelled event,
    Emitter<SubscriptionBlocState> emit,
  ) async {
    final current = await repository.current();
    final updated = current.copyWith(state: SubscriptionState.cancelled);
    await repository.save(updated);
    emit(
      state.copyWith(
        status: SubscriptionStatusX.ready,
        subscriptionStatus: updated,
        hasAccess: entitlements.hasAccess(updated, DateTime.now()),
        message: 'Subscription cancelled. Access continues until period end.',
      ),
    );
  }

  Future<void> _onSynced(
    SubscriptionSyncedFromBackend event,
    Emitter<SubscriptionBlocState> emit,
  ) async {
    await repository.save(event.status);
    emit(
      state.copyWith(
        status: SubscriptionStatusX.ready,
        subscriptionStatus: event.status,
        hasAccess: entitlements.hasAccess(event.status, DateTime.now()),
        trialDaysRemaining: entitlements.trialDaysRemaining(
          event.status,
          DateTime.now(),
        ),
      ),
    );
  }
}
