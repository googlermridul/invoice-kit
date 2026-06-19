import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart' show QuoteStatus;
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/quotes/data/repositories/quote_repository.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';
import 'package:invoice_kit/features/quotes/presentation/bloc/quotes_cubit.dart';
import 'package:invoice_kit/shared/helpers/id_generator.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class QuoteEditScreen extends StatefulWidget {
  const QuoteEditScreen({super.key, this.quoteId});
  final String? quoteId;

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  Quote? _quote;
  // BusinessProfile? _profile;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // final profile = await sl<BusinessProfileRepository>().load();
    final cubit = context.read<QuotesCubit>();
    final clientsCubit = context.read<ClientsCubit>();
    await clientsCubit.load();
    await cubit.load();
    if (widget.quoteId != null) {
      _quote = await sl<QuoteRepository>().byId(widget.quoteId!);
    }
    // _profile = profile;
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    if (_quote == null) return;
    if (_quote!.clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a client.')),
      );
      return;
    }
    await sl<QuoteRepository>().save(_quote!);
    if (_quote!.status == QuoteStatus.draft) {
      final profile = await sl<BusinessProfileRepository>().load();
      if (profile != null) {
        await sl<BusinessProfileRepository>().save(
          profile.copyWith(
            nextQuoteNumber: profile.nextQuoteNumber + 1,
          ),
        );
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote saved')));
      context.go('/quotes/${_quote!.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _quote == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final totals = InvoiceCalculator.forDocument(_quote!);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quoteId == null ? 'New quote' : 'Edit quote'),
        actions: [
          IconButton(icon: const Icon(Icons.save_outlined), onPressed: _save),
        ],
      ),
      body: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, cstate) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              InkWell(
                onTap: () async {
                  final id = await showModalBottomSheet<String>(
                    context: context,
                    builder: (_) => ListView(
                      shrinkWrap: true,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Pick a client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        ...cstate.clients.map(
                          (c) => ListTile(
                            title: Text(c.name),
                            subtitle: Text(c.company ?? c.email ?? ''),
                            onTap: () => Navigator.pop(context, c.id),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (id != null) {
                    setState(() => _quote = _quote!.copyWith(clientId: id));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quote for', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              cstate.clients.where((c) => c.id == _quote!.clientId).map((c) => c.name).firstOrNull ??
                                  'Tap to choose',
                              style: context.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _DateRow(
                label: 'Issue date',
                value: _quote!.issueDate,
                onPicked: (d) => setState(() => _quote = _quote!.copyWith(issueDate: d)),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DateRow(
                label: 'Valid until',
                value: _quote!.validUntil ?? DateTime.now().add(const Duration(days: 30)),
                onPicked: (d) => setState(() => _quote = _quote!.copyWith(validUntil: d)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Line items', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ..._quote!.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return _ItemEditor(
                  item: item,
                  onChanged: (updated) {
                    final list = [..._quote!.items];
                    list[idx] = updated;
                    setState(() => _quote = _quote!.copyWith(items: list));
                  },
                  onRemove: _quote!.items.length > 1
                      ? () => setState(
                          () => _quote = _quote!.copyWith(
                            items: [..._quote!.items]..removeAt(idx),
                          ),
                        )
                      : null,
                );
              }),
              TextButton.icon(
                onPressed: () {
                  setState(
                    () => _quote = _quote!.copyWith(
                      items: [
                        ..._quote!.items,
                        DocumentItem.empty(IdGenerator.create('item')),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add line item'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.outlineVariant),
                ),
                child: Column(
                  children: [
                    _row(context, 'Subtotal', totals.subtotal, _quote!.currency),
                    if (totals.lineTax > 0) _row(context, 'Line tax', totals.lineTax, _quote!.currency),
                    if (totals.globalTax > 0) _row(context, 'Global tax', totals.globalTax, _quote!.currency),
                    const Divider(),
                    _row(context, 'Total', totals.total, _quote!.currency, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: TextEditingController(text: _quote!.notes ?? ''),
                label: 'Notes',
                hint: 'Terms, scope, assumptions…',
                maxLines: 3,
                onChanged: (v) => _quote = _quote!.copyWith(notes: v),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: 'Save quote', onPressed: _save),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, double value, String currency, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: bold
                  ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
                  : context.textTheme.bodyMedium,
            ),
          ),
          Text(
            Formatters.currency(value, code: currency),
            style: bold
                ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
                : context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value, required this.onPicked});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2010),
          lastDate: DateTime(2100),
        );
        if (d != null) onPicked(d);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined),
            const SizedBox(width: AppSpacing.md),
            Text(label),
            const Spacer(),
            Text(Formatters.date(value), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({
    required this.item,
    required this.onChanged,
    this.onRemove,
  });

  final DocumentItem item;
  final ValueChanged<DocumentItem> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final _descCtrl = TextEditingController(text: widget.item.description);
  late final _qtyCtrl = TextEditingController(text: _formatQty(widget.item.quantity));
  late final _priceCtrl = TextEditingController(
    text: widget.item.unitPrice == 0 ? '' : widget.item.unitPrice.toStringAsFixed(2),
  );

  String _formatQty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  @override
  void dispose() {
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.item.copyWith(
        description: _descCtrl.text,
        quantity: double.tryParse(_qtyCtrl.text) ?? 1,
        unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _descCtrl,
            label: 'Description',
            hint: 'Service or product',
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _qtyCtrl,
                  label: 'Qty',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: _priceCtrl,
                  label: 'Unit price',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
          if (widget.onRemove != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remove'),
              ),
            ),
        ],
      ),
    );
  }
}
