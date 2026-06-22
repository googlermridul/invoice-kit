import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart'
    show QuoteStatus;
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/features/invoices/domain/usecases/invoice_calculator.dart';
import 'package:invoice_kit/features/quotes/data/repositories/quote_repository.dart';
import 'package:invoice_kit/features/quotes/domain/entities/quote.dart';
import 'package:invoice_kit/features/quotes/presentation/bloc/quotes_cubit.dart';
import 'package:invoice_kit/shared/helpers/id_generator.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class QuoteEditScreen extends StatefulWidget {
  const QuoteEditScreen({super.key, this.quoteId, this.presetClientId});
  final String? quoteId;

  /// Optional client id pulled from the `?clientId=…` query param when
  /// the screen is launched from the client detail screen.
  final String? presetClientId;

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  Quote? _quote;
  bool _loaded = false;
  bool _saving = false;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cubit = context.read<QuotesCubit>();
    final clientsCubit = context.read<ClientsCubit>();
    try {
      await clientsCubit.load();
      await cubit.load();
    } catch (_) {
      // Cubits surface the error in their state; keep going so the
      // form can still be opened and the user can retry.
    }
    if (widget.quoteId != null) {
      _quote = await sl<QuoteRepository>().byId(widget.quoteId!);
      if (_quote != null) _notesCtrl.text = _quote!.notes ?? '';
    } else {
      try {
        _quote = await cubit.createDraft(clientId: widget.presetClientId ?? '');
      } catch (_) {
        _quote = null;
      }
      _notesCtrl.text = _quote?.notes ?? '';
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    if (_saving || _quote == null) return;
    final q = _quote!;
    if (q.clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a client.')),
      );
      return;
    }
    final issueDay = DateTime(
      q.issueDate.year,
      q.issueDate.month,
      q.issueDate.day,
    );
    final validUntil = q.validUntil;
    if (validUntil != null && validUntil.isBefore(issueDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valid-until date cannot be before issue date.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final quoteRepo = sl<QuoteRepository>();
      final profileRepo = sl<BusinessProfileRepository>();
      final toSave = q.copyWith(notes: _notesCtrl.text);
      await quoteRepo.save(toSave);
      if (toSave.status == QuoteStatus.draft) {
        final profile = await profileRepo.load();
        if (profile != null) {
          await profileRepo.save(
            profile.copyWith(nextQuoteNumber: profile.nextQuoteNumber + 1),
          );
        }
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.quoteId == null ? 'Quote created' : 'Quote saved',
          ),
        ),
      );
      if (widget.quoteId == null) {
        router.pushReplacement(RoutePaths.quoteDetailPath(toSave.id));
      } else {
        router.pop();
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save quote: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _updateItems(List<DocumentItem> items) {
    setState(() => _quote = _quote!.copyWith(items: items));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = _quote;
    if (q == null) {
      return AppScaffold(
        title: widget.quoteId == null ? 'New quote' : 'Edit quote',
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not open the editor',
          subtitle:
              'There was a problem creating a draft. Please go back and try again.',
        ),
      );
    }
    final totals = InvoiceCalculator.forDocument(q);
    return AppScaffold(
      title: widget.quoteId == null ? 'New quote' : 'Edit quote',
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
                  'Quotes need a client. Add one and you can come back here.',
              actionLabel: 'Add client',
              onAction: () => GoRouter.of(context).push(RoutePaths.clientNew),
            );
          }
          final selectedName = cstate.clients
              .where((c) => c.id == q.clientId)
              .map((c) => c.name)
              .firstOrNull;
          return Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
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
                  label: 'Quote for',
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
                  onSelected: (id) => setState(
                    () => _quote = _quote!.copyWith(clientId: id),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(
                  title: 'Dates',
                  uppercase: true,
                  tone: SectionHeaderTone.primary,
                ),
                DateRow(
                  label: 'Issue date',
                  value: q.issueDate,
                  onPicked: (d) => setState(
                    () => _quote = _quote!.copyWith(issueDate: d),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DateRow(
                  label: 'Valid until',
                  value:
                      q.validUntil ??
                      DateTime.now().add(const Duration(days: 30)),
                  onPicked: (d) => setState(
                    () => _quote = _quote!.copyWith(validUntil: d),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(
                  title: 'Line items',
                  uppercase: true,
                  tone: SectionHeaderTone.primary,
                ),
                ...q.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return LineItemEditor(
                    key: ValueKey(item.id),
                    item: item,
                    validatorDescription: (v) =>
                        Validators.required(v, fieldName: 'Description'),
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
                      final list = [..._quote!.items];
                      list[index] = updated;
                      _updateItems(list);
                    },
                    onRemove: _quote!.items.length > 1
                        ? () => _updateItems(
                            [..._quote!.items]..removeAt(index),
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
                        ..._quote!.items,
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
                          code: q.currency,
                        ),
                      ),
                      if (totals.lineTax > 0)
                        KvRow(
                          label: 'Line tax',
                          value: Formatters.currency(
                            totals.lineTax,
                            code: q.currency,
                          ),
                        ),
                      if (totals.globalTax > 0)
                        KvRow(
                          label: 'Global tax',
                          value: Formatters.currency(
                            totals.globalTax,
                            code: q.currency,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      KvRow(
                        label: 'Total',
                        value: Formatters.currency(
                          totals.total,
                          code: q.currency,
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
                  hint: 'Terms, scope, assumptions…',
                  maxLines: 3,
                  onChanged: (v) => _quote = _quote!.copyWith(notes: v),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Save quote',
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
