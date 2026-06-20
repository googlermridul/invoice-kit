import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
import 'package:invoice_kit/core/widgets/kv_row.dart';
import 'package:invoice_kit/core/widgets/section_header.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart'
    show InvoiceStatus;
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
  bool _loaded = false;
  final _notesCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
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
      if (existing != null) {
        _notesCtrl.text = existing.notes ?? '';
        _termsCtrl.text = existing.terms ?? '';
      }
    } else {
      _notesCtrl.text = '';
      _termsCtrl.text = '';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved')),
      );
      if (widget.invoiceId == null) {
        GoRouter.of(context).pushReplacement('/invoices/${_invoice!.id}');
      } else {
        GoRouter.of(context).pop();
      }
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
    return AppScaffold(
      title: widget.invoiceId == null ? 'New invoice' : 'Edit invoice',
      actions: [
        IconButton(
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Save',
          onPressed: _save,
        ),
      ],
      body: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, cstate) {
          final selectedName = cstate.clients
              .where((c) => c.id == _invoice!.clientId)
              .map((c) => c.name)
              .firstOrNull;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              const SectionHeader(
                title: 'Client',
                uppercase: true,
                tone: SectionHeaderTone.primary,
              ),
              ClientPickerRow(
                label: 'Bill to',
                selectedName: cstate.clients.isEmpty ? null : selectedName,
                options: cstate.clients
                    .map(
                      (c) => (
                        id: c.id,
                        name: c.name,
                        subtitle: c.company ?? c.email,
                      ),
                    )
                    .toList(),
                emptyLabel: cstate.clients.isEmpty
                    ? 'Add a client first'
                    : 'Tap to choose',
                onSelected: (id) => setState(() {
                  _invoice = _invoice!.copyWith(clientId: id);
                }),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(
                title: 'Dates & currency',
                uppercase: true,
                tone: SectionHeaderTone.primary,
              ),
              DateRow(
                label: 'Issue date',
                value: _invoice!.issueDate,
                onPicked: (d) => setState(
                  () => _invoice = _invoice!.copyWith(issueDate: d),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DateRow(
                label: 'Due date',
                value: _invoice!.dueDate,
                onPicked: (d) => setState(
                  () => _invoice = _invoice!.copyWith(dueDate: d),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CurrencyPickerRow(
                selected: _invoice!.currency,
                options: {
                  defaultCurrency,
                  _invoice!.currency,
                  ...CurrencyCodes.common,
                }.toList(),
                onSelected: (c) => setState(
                  () => _invoice = _invoice!.copyWith(currency: c),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(
                title: 'Line items',
                uppercase: true,
                tone: SectionHeaderTone.primary,
              ),
              ..._invoice!.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return LineItemEditor(
                  item: item,
                  showTax: true,
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
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    _updateItems([
                      ..._invoice!.items,
                      DocumentItem.empty(IdGenerator.create('item')),
                    ]);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add line item'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  children: [
                    KvRow(
                      label: 'Subtotal',
                      value: Formatters.currency(
                        totals.subtotal,
                        code: _invoice!.currency,
                      ),
                    ),
                    if (totals.lineTax > 0)
                      KvRow(
                        label: 'Line tax',
                        value: Formatters.currency(
                          totals.lineTax,
                          code: _invoice!.currency,
                        ),
                      ),
                    if (totals.discount > 0)
                      KvRow(
                        label: 'Discount',
                        value: Formatters.currency(
                          -totals.discount,
                          code: _invoice!.currency,
                        ),
                      ),
                    if (totals.globalTax > 0)
                      KvRow(
                        label: 'Global tax',
                        value: Formatters.currency(
                          totals.globalTax,
                          code: _invoice!.currency,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    KvRow(
                      label: 'Total',
                      value: Formatters.currency(
                        totals.total,
                        code: _invoice!.currency,
                      ),
                      bold: true,
                      valueColor: context.colors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _notesCtrl,
                label: 'Notes',
                hint: 'Visible to the client',
                maxLines: 3,
                onChanged: (v) => _invoice = _invoice!.copyWith(notes: v),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _termsCtrl,
                label: 'Payment terms',
                hint: 'Payment due within 14 days.',
                maxLines: 3,
                onChanged: (v) => _invoice = _invoice!.copyWith(terms: v),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Save invoice',
                icon: Icons.check,
                onPressed: _save,
              ),
            ],
          );
        },
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
