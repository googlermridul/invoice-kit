import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/filters/document_filter.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/core/widgets/app_bottom_sheet.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart' show InvoiceStatus, QuoteStatus;
import 'package:invoice_kit/shared/widgets/buttons.dart';

/// Summary chips that show currently active filters, and a button to open
/// the [DocumentFilterSheet]. Tapping a chip's close icon clears that
/// specific filter.
class DocumentFilterChips extends StatelessWidget {
  const DocumentFilterChips({
    required this.filter,
    required this.onChanged,
    required this.onClear,
    required this.isInvoice,
    super.key,
  });

  final DocumentFilter filter;
  final ValueChanged<DocumentFilter> onChanged;
  final VoidCallback onClear;
  final bool isInvoice;

  @override
  Widget build(BuildContext context) {
    if (filter.isEmpty) return const SizedBox.shrink();
    final chips = <Widget>[];

    final statuses = isInvoice ? filter.invoiceStatuses : filter.quoteStatuses;
    if (statuses.isNotEmpty) {
      chips.add(
        _chip(
          context,
          label: 'Status · ${statuses.length}',
          onDelete: () => onChanged(
            filter.copyWith(
              invoiceStatuses: isInvoice ? <InvoiceStatus>{} : null,
              quoteStatuses: isInvoice ? null : <QuoteStatus>{},
            ),
          ),
        ),
      );
    }
    if (filter.minAmount != null) {
      chips.add(
        _chip(
          context,
          label: 'Min ${filter.minAmount!.toStringAsFixed(0)}',
          onDelete: () => onChanged(filter.copyWith(clearMin: true)),
        ),
      );
    }
    if (filter.maxAmount != null) {
      chips.add(
        _chip(
          context,
          label: 'Max ${filter.maxAmount!.toStringAsFixed(0)}',
          onDelete: () => onChanged(filter.copyWith(clearMax: true)),
        ),
      );
    }
    if (filter.issueAfter != null) {
      chips.add(
        _chip(
          context,
          label: 'From ${_short(filter.issueAfter!)}',
          onDelete: () => onChanged(filter.copyWith(clearAfter: true)),
        ),
      );
    }
    if (filter.issueBefore != null) {
      chips.add(
        _chip(
          context,
          label: 'To ${_short(filter.issueBefore!)}',
          onDelete: () => onChanged(filter.copyWith(clearBefore: true)),
        ),
      );
    }
    if (filter.sort != DocumentSort.newest) {
      chips.add(
        _chip(
          context,
          label: filter.sort.label,
          onDelete: () => onChanged(
            filter.copyWith(sort: DocumentSort.newest),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          ...chips,
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(HugeIconsStroke.cancel01, size: 18),
            label: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  static String _short(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _chip(
    BuildContext context, {
    required String label,
    required VoidCallback onDelete,
  }) {
    return InputChip(
      label: Text(label),
      onDeleted: onDelete,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: context.tokens.border),
      ),
    );
  }
}

/// Bottom sheet that lets the user adjust every part of the
/// [DocumentFilter] at once.
class DocumentFilterSheet extends StatefulWidget {
  const DocumentFilterSheet({
    required this.initial,
    required this.onApply,
    required this.isInvoice,
    super.key,
  });

  /// Show the document filter bottom sheet and return the selected filter.
  ///
  /// Returns `null` if the sheet is dismissed without Apply/Reset (e.g. the
  /// user taps outside the sheet or the back button). The Apply button
  /// pops with the current filter; the Reset button pops with an empty
  /// filter.
  static Future<DocumentFilter?> show({
    required BuildContext context,
    required DocumentFilter initial,
    required bool isInvoice,
  }) {
    return AppBottomSheet.show<DocumentFilter>(
      context: context,
      title: 'Filters',
      children: [
        DocumentFilterSheet(
          initial: initial,
          onApply: (_) {},
          isInvoice: isInvoice,
        ),
      ],
    );
  }

  final DocumentFilter initial;
  final ValueChanged<DocumentFilter> onApply;
  final bool isInvoice;

  @override
  State<DocumentFilterSheet> createState() => _DocumentFilterSheetState();
}

class _DocumentFilterSheetState extends State<DocumentFilterSheet> {
  late DocumentFilter _filter;
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
    if (_filter.minAmount != null) {
      _minCtrl.text = _filter.minAmount!.toStringAsFixed(0);
    }
    if (_filter.maxAmount != null) {
      _maxCtrl.text = _filter.maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _commitAmount() {
    final mn = double.tryParse(_minCtrl.text);
    final mx = double.tryParse(_maxCtrl.text);
    setState(() {
      _filter = _filter.copyWith(
        minAmount: mn,
        maxAmount: mx,
        clearMin: mn == null,
        clearMax: mx == null,
      );
    });
  }

  void _toggleInvoiceStatus(InvoiceStatus s, {required bool selected}) {
    final next = Set<InvoiceStatus>.of(_filter.invoiceStatuses);
    if (selected) {
      next.add(s);
    } else {
      next.remove(s);
    }
    setState(() => _filter = _filter.copyWith(invoiceStatuses: next));
  }

  void _toggleQuoteStatus(QuoteStatus s, {required bool selected}) {
    final next = Set<QuoteStatus>.of(_filter.quoteStatuses);
    if (selected) {
      next.add(s);
    } else {
      next.remove(s);
    }
    setState(() => _filter = _filter.copyWith(quoteStatuses: next));
  }

  @override
  Widget build(BuildContext context) {
    // Build the content of the bottom sheet; the static `show` method
    // presents this widget inside an AppBottomSheet.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          final selected = widget.isInvoice
              ? _filter.invoiceStatuses.length
              : _filter.quoteStatuses.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _SectionTitle('Status'),
                  const Spacer(),
                  if (selected > 0)
                    Text(
                      '$selected selected',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              // Multi-select: tap to toggle each status independently.
              // Separate loops so the type of `s` is known (InvoiceStatus or QuoteStatus).
              if (widget.isInvoice)
                _StatusWrap<InvoiceStatus>(
                  statuses: InvoiceStatus.values,
                  selected: _filter.invoiceStatuses,
                  labelOf: (s) => s.label,
                  onToggle: _toggleInvoiceStatus,
                )
              else
                _StatusWrap<QuoteStatus>(
                  statuses: QuoteStatus.values,
                  selected: _filter.quoteStatuses,
                  labelOf: (s) => s.label,
                  onToggle: _toggleQuoteStatus,
                ),
              const SizedBox(height: AppSpacing.md),
              _SectionTitle('Amount range'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _commitAmount(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _maxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _commitAmount(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionTitle('Date range'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(HugeIconsStroke.calendar01, size: 18),
                      label: Text(
                        _filter.issueAfter == null ? 'From' : _short(_filter.issueAfter!),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: _filter.issueAfter ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setLocal(() {
                            _filter = _filter.copyWith(issueAfter: picked);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(HugeIconsStroke.calendar01, size: 18),
                      label: Text(
                        _filter.issueBefore == null ? 'To' : _short(_filter.issueBefore!),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: _filter.issueBefore ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setLocal(() {
                            _filter = _filter.copyWith(issueBefore: picked);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionTitle('Sort by'),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: DocumentSort.values
                    .map(
                      (s) => ChoiceChip(
                        label: Text(s.label),
                        selected: _filter.sort == s,
                        onSelected: (sel) {
                          setLocal(() {
                            _filter = _filter.copyWith(
                              sort: sel ? s : DocumentSort.newest,
                            );
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onApply(DocumentFilter.empty);
                        Navigator.pop(ctx, DocumentFilter.empty);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Apply',
                      icon: HugeIconsStroke.tick01,
                      onPressed: () {
                        widget.onApply(_filter);
                        Navigator.pop(ctx, _filter);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _short(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Multi-select status row. Each chip toggles its own state independently
/// so users can pick e.g. Paid + Overdue + Sent.
class _StatusWrap<T> extends StatelessWidget {
  const _StatusWrap({
    required this.statuses,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
  });

  final List<T> statuses;
  final Set<T> selected;
  final String Function(T) labelOf;
  final void Function(T status, {required bool selected}) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final s in statuses)
          FilterChip(
            label: Text(labelOf(s)),
            selected: selected.contains(s),
            showCheckmark: true,
            onSelected: (sel) => onToggle(s, selected: sel),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
