import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/validators/validators.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
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
import 'package:invoice_kit/features/invoices/domain/entities/pdf_template.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/invoices/presentation/bloc/invoices_cubit.dart';
import 'package:invoice_kit/shared/helpers/id_generator.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class InvoiceEditScreen extends StatefulWidget {
  const InvoiceEditScreen({super.key, this.invoiceId, this.presetClientId});
  final String? invoiceId;

  /// Optional client id pulled from the `?clientId=…` query param when
  /// the screen is launched from the client detail screen.
  final String? presetClientId;

  @override
  State<InvoiceEditScreen> createState() => _InvoiceEditScreenState();
}

class _InvoiceEditScreenState extends State<InvoiceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  Invoice? _invoice;
  BusinessProfile? _profile;
  bool _loaded = false;
  bool _saving = false;
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
    final cubit = context.read<InvoicesCubit>();
    final clientsCubit = context.read<ClientsCubit>();
    final profile = await repo.load();
    try {
      await clientsCubit.load();
      await cubit.load();
    } catch (_) {
      // Cubits surface the error in their state; keep going so the
      // form can still be opened and the user can retry.
    }
    if (widget.invoiceId != null) {
      final existing = await sl<InvoiceRepository>().byId(widget.invoiceId!);
      _invoice = existing;
      if (existing != null) {
        _notesCtrl.text = existing.notes ?? '';
        _termsCtrl.text = existing.terms ?? '';
      }
    } else {
      try {
        _invoice = await cubit.createDraft(
          clientId: widget.presetClientId ?? '',
        );
      } catch (e) {
        _invoice = null;
      }
      _notesCtrl.text = _invoice?.notes ?? '';
      _termsCtrl.text = _invoice?.terms ?? '';
    }
    _profile = profile;
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    if (_saving || _invoice == null) return;
    final inv = _invoice!;
    if (inv.clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a client.')),
      );
      return;
    }
    final issueDay = DateTime(
      inv.issueDate.year,
      inv.issueDate.month,
      inv.issueDate.day,
    );
    if (inv.dueDate.isBefore(issueDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Due date cannot be before issue date.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final invoiceRepo = sl<InvoiceRepository>();
      final profileRepo = sl<BusinessProfileRepository>();
      final toSave = inv.copyWith(
        notes: _notesCtrl.text,
        terms: _termsCtrl.text,
      );
      await invoiceRepo.save(toSave);
      if (toSave.status == InvoiceStatus.draft) {
        final profile = await profileRepo.load();
        if (profile != null) {
          await profileRepo.save(
            profile.copyWith(
              nextInvoiceNumber: profile.nextInvoiceNumber + 1,
            ),
          );
        }
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.invoiceId == null ? 'Invoice created' : 'Invoice saved',
          ),
        ),
      );
      if (widget.invoiceId == null) {
        router.pushReplacement(RoutePaths.invoiceDetailPath(toSave.id));
      } else {
        router.pop();
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save invoice: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _updateItems(List<DocumentItem> items) {
    setState(() {
      _invoice = _invoice!.copyWith(items: items);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final inv = _invoice;
    if (inv == null) {
      return AppScaffold(
        title: widget.invoiceId == null ? 'New invoice' : 'Edit invoice',
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not open the editor',
          subtitle:
              'There was a problem creating a draft. Please go back and try again.',
        ),
      );
    }
    final totals = InvoiceCalculator.forDocument(inv);
    final defaultCurrency = _profile?.defaultCurrency ?? 'USD';
    return AppScaffold(
      title: widget.invoiceId == null ? 'New invoice' : 'Edit invoice',
      actions: [
        IconButton(
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Save',
          onPressed: _saving ? null : _save,
        ),
      ],
      body: BlocBuilder<ClientsCubit, ClientsState>(
        builder: (context, cstate) {
          if (cstate.clients.isEmpty && !cstate.loading) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'Add a client first',
              subtitle:
                  'Invoices need a client. Add one and you can come back here.',
              actionLabel: 'Add client',
              onAction: () => GoRouter.of(context).push(RoutePaths.clientNew),
            );
          }
          final selectedName = cstate.clients
              .where((c) => c.id == inv.clientId)
              .map((c) => c.name)
              .firstOrNull;
          return Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              children: [
                const SectionHeader(
                  title: 'Client',
                  uppercase: true,
                  tone: SectionHeaderTone.primary,
                ),
                ClientPickerRow(
                  label: 'Bill to',
                  selectedName: selectedName,
                  options: cstate.clients
                      .map(
                        (c) => (
                          id: c.id,
                          name: c.name,
                          subtitle: c.company ?? c.email,
                        ),
                      )
                      .toList(),
                  emptyLabel: 'Tap to choose',
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
                  value: inv.issueDate,
                  onPicked: (d) => setState(
                    () => _invoice = _invoice!.copyWith(issueDate: d),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DateRow(
                  label: 'Due date',
                  value: inv.dueDate,
                  onPicked: (d) => setState(
                    () => _invoice = _invoice!.copyWith(dueDate: d),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SearchableCurrencyPickerRow(
                  selected: inv.currency,
                  options: {
                    defaultCurrency,
                    inv.currency,
                    ...CurrencyCodes.common,
                  }.toList(),
                  onSelected: (c) => setState(
                    () => _invoice = _invoice!.copyWith(currency: c),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(
                  title: 'PDF template',
                  uppercase: true,
                  tone: SectionHeaderTone.primary,
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < PdfTemplateIds.all.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            indent: AppSpacing.md,
                            endIndent: AppSpacing.md,
                          ),
                        RadioListTile<String>(
                          value: PdfTemplateIds.all[i],
                          // ignore: deprecated_member_use
                          groupValue:
                              inv.pdfTemplateId ??
                              _profile?.selectedPdfTemplate ??
                              PdfTemplateIds.classic,
                          onChanged: (v) => setState(() {
                            _invoice = _invoice!.copyWith(
                              pdfTemplateId: v,
                              clearPdfTemplate: v == null,
                            );
                          }),
                          title: Text(
                            PdfTemplateIds.displayName(PdfTemplateIds.all[i]),
                          ),
                          subtitle: Text(
                            PdfTemplateIds.description(PdfTemplateIds.all[i]),
                            style: TextStyle(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(
                  title: 'Line items',
                  uppercase: true,
                  tone: SectionHeaderTone.primary,
                ),
                ...inv.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return LineItemEditor(
                    key: ValueKey(item.id),
                    item: item,
                    showTax: true,
                    validatorDescription: (v) => Validators.required(
                      v,
                      fieldName: 'Description',
                    ),
                    validatorQuantity: (v) =>
                        Validators.positiveNumber(v, fieldName: 'Quantity'),
                    validatorUnitPrice: (v) => Validators.nonNegativeNumber(
                      v,
                      fieldName: 'Unit price',
                    ),
                    validatorTaxRate: (v) => Validators.nonNegativeNumber(
                      v,
                      fieldName: 'Tax',
                    ),
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
                          code: inv.currency,
                        ),
                      ),
                      if (totals.lineTax > 0)
                        KvRow(
                          label: 'Line tax',
                          value: Formatters.currency(
                            totals.lineTax,
                            code: inv.currency,
                          ),
                        ),
                      if (totals.discount > 0)
                        KvRow(
                          label: 'Discount',
                          value: Formatters.currency(
                            -totals.discount,
                            code: inv.currency,
                          ),
                        ),
                      if (totals.globalTax > 0)
                        KvRow(
                          label: 'Global tax',
                          value: Formatters.currency(
                            totals.globalTax,
                            code: inv.currency,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      KvRow(
                        label: 'Total',
                        value: Formatters.currency(
                          totals.total,
                          code: inv.currency,
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
                  hint: 'Payment due within 3 days.',
                  maxLines: 3,
                  onChanged: (v) => _invoice = _invoice!.copyWith(terms: v),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Save invoice',
                  icon: Icons.check,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
