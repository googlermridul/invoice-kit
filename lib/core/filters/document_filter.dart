import 'package:invoice_kit/features/invoices/domain/entities/document.dart'
    show InvoiceStatus, QuoteStatus;
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';

/// User-tunable filters applied on top of the underlying list of documents
/// (invoices or quotes). Kept tiny so the UI can serialize/de-serialize
/// trivially when persisting between launches.
class DocumentFilter {
  const DocumentFilter({
    this.invoiceStatus,
    this.quoteStatus,
    this.clientId,
    this.minAmount,
    this.maxAmount,
    this.issueAfter,
    this.issueBefore,
    this.sort = DocumentSort.newest,
  });

  final InvoiceStatus? invoiceStatus;
  final QuoteStatus? quoteStatus;
  final String? clientId;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? issueAfter;
  final DateTime? issueBefore;
  final DocumentSort sort;

  static const empty = DocumentFilter();

  bool get isEmpty =>
      invoiceStatus == null &&
      quoteStatus == null &&
      clientId == null &&
      minAmount == null &&
      maxAmount == null &&
      issueAfter == null &&
      issueBefore == null &&
      sort == DocumentSort.newest;

  int get activeCount {
    var n = 0;
    if (invoiceStatus != null || quoteStatus != null) n++;
    if (clientId != null) n++;
    if (minAmount != null) n++;
    if (maxAmount != null) n++;
    if (issueAfter != null) n++;
    if (issueBefore != null) n++;
    if (sort != DocumentSort.newest) n++;
    return n;
  }

  DocumentFilter copyWith({
    InvoiceStatus? invoiceStatus,
    QuoteStatus? quoteStatus,
    String? clientId,
    double? minAmount,
    double? maxAmount,
    DateTime? issueAfter,
    DateTime? issueBefore,
    DocumentSort? sort,
    bool clearInvoiceStatus = false,
    bool clearQuoteStatus = false,
    bool clearClient = false,
    bool clearMin = false,
    bool clearMax = false,
    bool clearAfter = false,
    bool clearBefore = false,
  }) {
    return DocumentFilter(
      invoiceStatus: clearInvoiceStatus
          ? null
          : (invoiceStatus ?? this.invoiceStatus),
      quoteStatus: clearQuoteStatus ? null : (quoteStatus ?? this.quoteStatus),
      clientId: clearClient ? null : (clientId ?? this.clientId),
      minAmount: clearMin ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMax ? null : (maxAmount ?? this.maxAmount),
      issueAfter: clearAfter ? null : (issueAfter ?? this.issueAfter),
      issueBefore: clearBefore ? null : (issueBefore ?? this.issueBefore),
      sort: sort ?? this.sort,
    );
  }
}

enum DocumentSort { newest, oldest, amountHigh, amountLow, dueSoon }

extension DocumentSortX on DocumentSort {
  String get label => switch (this) {
    DocumentSort.newest => 'Newest first',
    DocumentSort.oldest => 'Oldest first',
    DocumentSort.amountHigh => 'Amount · high to low',
    DocumentSort.amountLow => 'Amount · low to high',
    DocumentSort.dueSoon => 'Due date · soonest',
  };
}

List<Invoice> filterInvoices({
  required List<Invoice> invoices,
  required DocumentFilter filter,
  required String query,
}) {
  Iterable<Invoice> result = invoices;
  if (query.trim().isNotEmpty) {
    final q = query.trim().toLowerCase();
    result = result.where(
      (i) =>
          i.number.toLowerCase().contains(q) ||
          (i.notes ?? '').toLowerCase().contains(q),
    );
  }
  if (filter.invoiceStatus != null) {
    result = result.where((i) => i.status == filter.invoiceStatus);
  }
  if (filter.clientId != null) {
    result = result.where((i) => i.clientId == filter.clientId);
  }
  if (filter.minAmount != null) {
    result = result.where((i) => i.total >= filter.minAmount!);
  }
  if (filter.maxAmount != null) {
    result = result.where((i) => i.total <= filter.maxAmount!);
  }
  if (filter.issueAfter != null) {
    result = result.where(
      (i) => !i.issueDate.isBefore(filter.issueAfter!),
    );
  }
  if (filter.issueBefore != null) {
    result = result.where(
      (i) => !i.issueDate.isAfter(filter.issueBefore!),
    );
  }
  final list = result.toList()
    ..sort((a, b) {
      switch (filter.sort) {
        case DocumentSort.newest:
          return b.issueDate.compareTo(a.issueDate);
        case DocumentSort.oldest:
          return a.issueDate.compareTo(b.issueDate);
        case DocumentSort.amountHigh:
          return b.total.compareTo(a.total);
        case DocumentSort.amountLow:
          return a.total.compareTo(b.total);
        case DocumentSort.dueSoon:
          return a.dueDate.compareTo(b.dueDate);
      }
    });
  return list;
}

List<Quote> filterQuotes({
  required List<Quote> quotes,
  required DocumentFilter filter,
  required String query,
}) {
  Iterable<Quote> result = quotes;
  if (query.trim().isNotEmpty) {
    final q = query.trim().toLowerCase();
    result = result.where(
      (q0) =>
          q0.number.toLowerCase().contains(q) ||
          (q0.notes ?? '').toLowerCase().contains(q),
    );
  }
  if (filter.quoteStatus != null) {
    result = result.where((q0) => q0.status == filter.quoteStatus);
  }
  if (filter.clientId != null) {
    result = result.where((q0) => q0.clientId == filter.clientId);
  }
  if (filter.minAmount != null) {
    result = result.where((q0) => q0.total >= filter.minAmount!);
  }
  if (filter.maxAmount != null) {
    result = result.where((q0) => q0.total <= filter.maxAmount!);
  }
  if (filter.issueAfter != null) {
    result = result.where(
      (q0) => !q0.issueDate.isBefore(filter.issueAfter!),
    );
  }
  if (filter.issueBefore != null) {
    result = result.where(
      (q0) => !q0.issueDate.isAfter(filter.issueBefore!),
    );
  }
  final list = result.toList()
    ..sort((a, b) {
      switch (filter.sort) {
        case DocumentSort.newest:
          return b.issueDate.compareTo(a.issueDate);
        case DocumentSort.oldest:
          return a.issueDate.compareTo(b.issueDate);
        case DocumentSort.amountHigh:
          return b.total.compareTo(a.total);
        case DocumentSort.amountLow:
          return a.total.compareTo(b.total);
        case DocumentSort.dueSoon:
          return a.dueDate.compareTo(b.dueDate);
      }
    });
  return list;
}
