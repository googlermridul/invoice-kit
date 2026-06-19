part of 'quotes_cubit.dart';

abstract class QuotesEvent extends Equatable {
  const QuotesEvent();
  @override
  List<Object?> get props => const [];
}

class QuotesLoadRequested extends QuotesEvent {
  const QuotesLoadRequested();
}

class QuotesDeleteRequested extends QuotesEvent {
  const QuotesDeleteRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class QuotesDuplicateRequested extends QuotesEvent {
  const QuotesDuplicateRequested(this.quote);
  final Quote quote;
  @override
  List<Object?> get props => [quote];
}

class QuotesStatusChanged extends QuotesEvent {
  const QuotesStatusChanged(this.quote, this.status);
  final Quote quote;
  final QuoteStatus status;
  @override
  List<Object?> get props => [quote, status];
}
