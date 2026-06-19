import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart' show InvoiceStatus;
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/entities/invoice.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/invoices/presentation/bloc/invoices_cubit.dart';
import 'package:invoice_kit/shared/helpers/id_generator.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class InvoiceEditScreen extends StatefulWidget {
  const InvoiceEditScreen({super.key, this.invoiceId});
  final String? invoiceId;

  @override
  State<InvoiceEditScreen> createState() => _InvoiceEditScreenState();
}

class _InvoiceEditScreenState extends State<InvoiceEditScreen> {
  Invoice? _invoice;
  BusinessProfile? _profile;
  // Client? _selectedClient;
  bool _loaded = false;

  @override
  Future<void> initState() async {
    super.initState();
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = sl<BusinessProfileRepository>();
    final profile = await repo.load();
    final cubit = context.read<InvoicesCubit>();
    final clientsCubit = context.read<ClientsCubit>();
    await clientsCubit.load();
    await cubit.load();
    if (widget.invoiceId != null) {
      final existing = await sl<InvoiceRepository>().byId(widget.invoiceId!);
      _invoice = existing;
      // if (existing != null) {
      //   _selectedClient = clientsCubit.state.clients
      //       .where((c) => c.id == existing.clientId)
      //       .cast<Client?>()
      //       .firstOrNull;
      // }
    }
    _profile = profile;
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    if (_invoice == null) return;
    if (_invoice!.clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a client.')),
      );
      return;
    }
    final invoiceRepo = sl<InvoiceRepository>();
    final profileRepo = sl<BusinessProfileRepository>();
    await invoiceRepo.save(_invoice!);
    if (_invoice!.status == InvoiceStatus.draft) {
      final profile = await profileRepo.load();
      if (profile != null) {
        await profileRepo.save(
          profile.copyWith(
            nextInvoiceNumber: profile.nextInvoiceNumber + 1,
          ),
        );
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice saved')));
      context.go('/invoices/${_invoice!.id}');
    }
  }

  void _updateItems(List<DocumentItem> items) {
    setState(() {
      _invoice = _invoice!.copyWith(items: items);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _invoice == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final totals = InvoiceCalculator.forDocument(_invoice!);
    final defaultCurrency = _profile?.defaultCurrency ?? 'USD';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoiceId == null ? 'New invoice' : 'Edit invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _save,
          ),
        ],
      ),
      body: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, cstate) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _ClientPicker(
                clients: cstate.clients,
                selectedId: _invoice!.clientId,
                onChanged: (id) => setState(() {
                  // _selectedClient = cstate.clients.where((c) => c.id == id).cast<Client?>().firstOrNull;
                  _invoice = _invoice!.copyWith(clientId: id);
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              _DateRow(
                label: 'Issue date',
                value: _invoice!.issueDate,
                onPicked: (d) => setState(() => _invoice = _invoice!.copyWith(issueDate: d)),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DateRow(
                label: 'Due date',
                value: _invoice!.dueDate,
                onPicked: (d) => setState(() => _invoice = _invoice!.copyWith(dueDate: d)),
              ),
              const SizedBox(height: AppSpacing.sm),
              _CurrencyPicker(
                currency: _invoice!.currency,
                fallback: defaultCurrency,
                onChanged: (c) => setState(() => _invoice = _invoice!.copyWith(currency: c)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Line items', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ..._invoice!.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _ItemEditor(
                  item: item,
                  onChanged: (updated) {
                    final list = [..._invoice!.items];
                    list[index] = updated;
                    _updateItems(list);
                  },
                  onRemove: _invoice!.items.length > 1
                      ? () => _updateItems(
                          [..._invoice!.items]..removeAt(index),
                        )
                      : null,
                );
              }),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () {
                  _updateItems([
                    ..._invoice!.items,
                    DocumentItem.empty(IdGenerator.create('item')),
                  ]);
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
                    _totalRow(context, 'Subtotal', totals.subtotal, _invoice!.currency),
                    if (totals.lineTax > 0) _totalRow(context, 'Line tax', totals.lineTax, _invoice!.currency),
                    if (totals.discount > 0) _totalRow(context, 'Discount', -totals.discount, _invoice!.currency),
                    if (totals.globalTax > 0) _totalRow(context, 'Global tax', totals.globalTax, _invoice!.currency),
                    const Divider(),
                    _totalRow(context, 'Total', totals.total, _invoice!.currency, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: TextEditingController(text: _invoice!.notes ?? ''),
                label: 'Notes',
                hint: 'Visible to the client',
                maxLines: 3,
                onChanged: (v) => _invoice = _invoice!.copyWith(notes: v),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: TextEditingController(text: _invoice!.terms ?? ''),
                label: 'Payment terms',
                hint: 'Payment due within 14 days.',
                maxLines: 3,
                onChanged: (v) => _invoice = _invoice!.copyWith(terms: v),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: 'Save invoice', onPressed: _save),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Widget _totalRow(BuildContext context, String label, double value, String currency, {bool bold = false}) {
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

class _ClientPicker extends StatelessWidget {
  const _ClientPicker({
    required this.clients,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Client> clients;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: clients.isEmpty
          ? () => context.go('/clients/new')
          : () async {
              final id = await showModalBottomSheet<String>(
                context: context,
                builder: (_) => ListView(
                  shrinkWrap: true,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Pick a client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    ...clients.map(
                      (c) => ListTile(
                        title: Text(c.name),
                        subtitle: Text(c.company ?? c.email ?? ''),
                        onTap: () => Navigator.pop(context, c.id),
                      ),
                    ),
                  ],
                ),
              );
              if (id != null) onChanged(id);
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
                  const Text('Bill to', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    clients.where((c) => c.id == selectedId).map((c) => c.name).firstOrNull ??
                        (clients.isEmpty ? 'Add a client first' : 'Tap to choose'),
                    style: context.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
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

class _CurrencyPicker extends StatelessWidget {
  const _CurrencyPicker({
    required this.currency,
    required this.fallback,
    required this.onChanged,
  });

  final String currency;
  final String fallback;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final codes = {currency, fallback};
    return DropdownButtonFormField<String>(
      initialValue: currency,
      decoration: const InputDecoration(
        labelText: 'Currency',
        border: OutlineInputBorder(),
      ),
      items: codes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
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
  late final _taxCtrl = TextEditingController(
    text: widget.item.taxRate == 0 ? '' : widget.item.taxRate.toStringAsFixed(0),
  );

  String _formatQty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  @override
  void dispose() {
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.item.copyWith(
        description: _descCtrl.text,
        quantity: double.tryParse(_qtyCtrl.text) ?? 1,
        unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
        taxRate: double.tryParse(_taxCtrl.text) ?? 0,
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
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: _taxCtrl,
                  label: 'Tax %',
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
