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
    this.clientName,
    super.key,
  });

  final DocumentFilter filter;
  final ValueChanged<DocumentFilter> onChanged;
  final VoidCallback onClear;
  final bool isInvoice;
  final String? clientName;

  @override
  Widget build(BuildContext context) {
    if (filter.isEmpty) return const SizedBox.shrink();
    final chips = <Widget>[];

    final status = isInvoice ? filter.invoiceStatus : filter.quoteStatus;
    if (status != null) {
      chips.add(
        _chip(
          context,
          // label: 'Status · ${status.label}',
          label: 'Status · ${filter.invoiceStatus}',
          onDelete: () => onChanged(
            filter.copyWith(
              clearInvoiceStatus: isInvoice,
              clearQuoteStatus: !isInvoice,
            ),
          ),
        ),
      );
    }
    if (filter.clientId != null) {
      chips.add(
        _chip(
          context,
          label: 'Client · ${clientName ?? "Selected"}',
          onDelete: () => onChanged(filter.copyWith(clearClient: true)),
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
    required this.clients,
    super.key,
  });

  /// Show the document filter bottom sheet and return the selected filter.
  static Future<DocumentFilter?> show({
    required BuildContext context,
    required DocumentFilter initial,
    required bool isInvoice,
    required List<({String id, String name})> clients,
  }) async {
    DocumentFilter? result;
    await AppBottomSheet.show<DocumentFilter>(
      context: context,
      title: 'Filters',
      children: [
        DocumentFilterSheet(
          initial: initial,
          onApply: (f) => result = f,
          isInvoice: isInvoice,
          clients: clients,
        ),
      ],
    ).then((value) => result = value);
    return result;
  }

  final DocumentFilter initial;
  final ValueChanged<DocumentFilter> onApply;
  final bool isInvoice;
  final List<({String id, String name})> clients;

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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle('Status'),
              // Separate loops so the type of `s` is known (InvoiceStatus or QuoteStatus).
              if (widget.isInvoice) ...[
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: InvoiceStatus.values
                      .map(
                        (s) => ChoiceChip(
                          label: Text(s.label),
                          selected: _filter.invoiceStatus == s,
                          onSelected: (sel) {
                            setLocal(() {
                              _filter = _filter.copyWith(
                                invoiceStatus: sel ? s : null,
                                clearInvoiceStatus: !sel,
                              );
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ] else ...[
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: QuoteStatus.values
                      .map(
                        (s) => ChoiceChip(
                          label: Text(s.label),
                          selected: _filter.quoteStatus == s,
                          onSelected: (sel) {
                            setLocal(() {
                              _filter = _filter.copyWith(
                                quoteStatus: sel ? s : null,
                                clearQuoteStatus: !sel,
                              );
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _SectionTitle('Client'),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final c in widget.clients)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _filter.clientId == c.id,
                      onSelected: (sel) {
                        setLocal(() {
                          _filter = _filter.copyWith(
                            clientId: sel ? c.id : null,
                            clearClient: !sel,
                          );
                        });
                      },
                    ),
                ],
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
                        Navigator.pop(ctx);
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
                        Navigator.pop(ctx);
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
