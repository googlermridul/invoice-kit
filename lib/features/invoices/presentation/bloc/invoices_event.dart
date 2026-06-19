part of 'invoices_cubit.dart';

abstract class InvoicesEvent extends Equatable {
  const InvoicesEvent();
  @override
  List<Object?> get props => const [];
}

class InvoicesLoadRequested extends InvoicesEvent {
  const InvoicesLoadRequested();
}

class InvoicesDeleteRequested extends InvoicesEvent {
  const InvoicesDeleteRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class InvoicesDuplicateRequested extends InvoicesEvent {
  const InvoicesDuplicateRequested(this.invoice);
  final Invoice invoice;
  @override
  List<Object?> get props => [invoice];
}

class InvoicesStatusChanged extends InvoicesEvent {
  const InvoicesStatusChanged(this.invoice, this.status);
  final Invoice invoice;
  final InvoiceStatus status;
  @override
  List<Object?> get props => [invoice, status];
}
