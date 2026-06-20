import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/fx/data/repositories/fx_repository.dart';
import 'package:invoice_kit/features/fx/domain/entities/fx_rate.dart';
import 'package:invoice_kit/features/fx/domain/usecases/fx_converter.dart';

part 'fx_event.dart';
part 'fx_state.dart';

class FxCubit extends Cubit<FxState> {
  FxCubit({required this.repository}) : super(FxState.initial());

  final FxRepository repository;
  final FxConverter converter = const FxConverter();

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final rates = await repository.all();
    final lastUpdated = rates.isEmpty
        ? null
        : rates.map((r) => r.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);
    emit(
      state.copyWith(loading: false, rates: rates, lastUpdated: lastUpdated),
    );
  }

  Future<void> refresh({String base = 'USD'}) async {
    emit(state.copyWith(refreshing: true));
    try {
      final rates = await repository.refresh(base: base);
      final lastUpdated = rates.isEmpty
          ? null
          : rates
                .map((r) => r.updatedAt)
                .reduce((a, b) => a.isAfter(b) ? a : b);
      emit(
        state.copyWith(
          refreshing: false,
          rates: rates,
          lastUpdated: lastUpdated,
          base: base,
        ),
      );
    } catch (e) {
      emit(state.copyWith(refreshing: false, error: e.toString()));
    }
  }

  double convert({
    required double amount,
    required String from,
    required String to,
  }) =>
      converter.convert(amount: amount, from: from, to: to, rates: state.rates);
}
