import 'package:invoice_kit/features/invoices/domain/entities/document.dart'
    show InvoiceStatus, QuoteStatus;
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';

/// User-tunable filters applied on top of the underlying list of documents
/// (invoices or quotes). Kept tiny so the UI can serialize/de-serialize
/// trivially when persisting between launches.
class DocumentFilter {
  const DocumentFilter({
    this.invoiceStatuses = const <InvoiceStatus>{},
    this.quoteStatuses = const <QuoteStatus>{},
    this.minAmount,
    this.maxAmount,
    this.issueAfter,
    this.issueBefore,
    this.sort = DocumentSort.newest,
  });

  /// Set of selected invoice statuses. Empty means "all statuses".
  final Set<InvoiceStatus> invoiceStatuses;

  /// Set of selected quote statuses. Empty means "all statuses".
  final Set<QuoteStatus> quoteStatuses;

  final double? minAmount;
  final double? maxAmount;
  final DateTime? issueAfter;
  final DateTime? issueBefore;
  final DocumentSort sort;

  static const empty = DocumentFilter();

  bool get isEmpty =>
      invoiceStatuses.isEmpty &&
      quoteStatuses.isEmpty &&
      minAmount == null &&
      maxAmount == null &&
      issueAfter == null &&
      issueBefore == null &&
      sort == DocumentSort.newest;

  int get activeCount {
    var n = 0;
    if (invoiceStatuses.isNotEmpty || quoteStatuses.isNotEmpty) n++;
    if (minAmount != null) n++;
    if (maxAmount != null) n++;
    if (issueAfter != null) n++;
    if (issueBefore != null) n++;
    if (sort != DocumentSort.newest) n++;
    return n;
  }

  DocumentFilter copyWith({
    Set<InvoiceStatus>? invoiceStatuses,
    Set<QuoteStatus>? quoteStatuses,
    double? minAmount,
    double? maxAmount,
    DateTime? issueAfter,
    DateTime? issueBefore,
    DocumentSort? sort,
    bool clearMin = false,
    bool clearMax = false,
    bool clearAfter = false,
    bool clearBefore = false,
  }) {
    return DocumentFilter(
      invoiceStatuses: invoiceStatuses ?? this.invoiceStatuses,
      quoteStatuses: quoteStatuses ?? this.quoteStatuses,
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

/// Whether [clientName] contains [q] (case-insensitive). Returns false
/// when [clientName] is null.
bool _matchesClientName(String? clientName, String q) {
  if (clientName == null) return false;
  return clientName.toLowerCase().contains(q);
}

List<Invoice> filterInvoices({
  required List<Invoice> invoices,
  required DocumentFilter filter,
  required String query,
  String? Function(Invoice)? resolveClientName,
}) {
  Iterable<Invoice> result = invoices;
  if (query.trim().isNotEmpty) {
    final q = query.trim().toLowerCase();
    result = result.where(
      (i) =>
          i.number.toLowerCase().contains(q) ||
          (i.notes ?? '').toLowerCase().contains(q) ||
          _matchesClientName(resolveClientName?.call(i), q),
    );
  }
  // Multi-select status: empty set => no constraint, otherwise OR-match.
  if (filter.invoiceStatuses.isNotEmpty) {
    result = result.where((i) => filter.invoiceStatuses.contains(i.status));
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
  String? Function(Quote)? resolveClientName,
}) {
  Iterable<Quote> result = quotes;
  if (query.trim().isNotEmpty) {
    final q = query.trim().toLowerCase();
    result = result.where(
      (q0) =>
          q0.number.toLowerCase().contains(q) ||
          (q0.notes ?? '').toLowerCase().contains(q) ||
          _matchesClientName(resolveClientName?.call(q0), q),
    );
  }
  // Multi-select status: empty set => no constraint, otherwise OR-match.
  if (filter.quoteStatuses.isNotEmpty) {
    result = result.where((q0) => filter.quoteStatuses.contains(q0.status));
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
