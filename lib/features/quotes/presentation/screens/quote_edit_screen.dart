import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
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
  const QuoteEditScreen({super.key, this.quoteId});
  final String? quoteId;

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  Quote? _quote;
  bool _loaded = false;
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
    await clientsCubit.load();
    await cubit.load();
    if (widget.quoteId != null) {
      _quote = await sl<QuoteRepository>().byId(widget.quoteId!);
      if (_quote != null) _notesCtrl.text = _quote!.notes ?? '';
    } else {
      _notesCtrl.text = '';
    }
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
          profile.copyWith(nextQuoteNumber: profile.nextQuoteNumber + 1),
        );
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote saved')),
      );
      if (widget.quoteId == null) {
        GoRouter.of(context).pushReplacement('/quotes/${_quote!.id}');
      } else {
        GoRouter.of(context).pop();
      }
    }
  }

  void _updateItems(List<DocumentItem> items) {
    setState(() => _quote = _quote!.copyWith(items: items));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _quote == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final totals = InvoiceCalculator.forDocument(_quote!);
    return AppScaffold(
      title: widget.quoteId == null ? 'New quote' : 'Edit quote',
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
              .where((c) => c.id == _quote!.clientId)
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
                value: _quote!.issueDate,
                onPicked: (d) => setState(
                  () => _quote = _quote!.copyWith(issueDate: d),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DateRow(
                label: 'Valid until',
                value:
                    _quote!.validUntil ??
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
              ..._quote!.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return LineItemEditor(
                  item: item,
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
                        code: _quote!.currency,
                      ),
                    ),
                    if (totals.lineTax > 0)
                      KvRow(
                        label: 'Line tax',
                        value: Formatters.currency(
                          totals.lineTax,
                          code: _quote!.currency,
                        ),
                      ),
                    if (totals.globalTax > 0)
                      KvRow(
                        label: 'Global tax',
                        value: Formatters.currency(
                          totals.globalTax,
                          code: _quote!.currency,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    KvRow(
                      label: 'Total',
                      value: Formatters.currency(
                        totals.total,
                        code: _quote!.currency,
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
