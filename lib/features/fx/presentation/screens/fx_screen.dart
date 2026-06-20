import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/widgets.dart';
import 'package:invoice_kit/features/fx/presentation/bloc/fx_cubit.dart';
import 'package:invoice_kit/shared/widgets/app_text_field.dart';

class FxScreen extends StatefulWidget {
  const FxScreen({super.key});

  @override
  State<FxScreen> createState() => _FxScreenState();
}

class _FxScreenState extends State<FxScreen> {
  String _from = 'USD';
  String _to = 'EUR';
  double _amount = 100;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: _amount.toString());
    context.read<FxCubit>().load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _swap() {
    setState(() {
      final t = _from;
      _from = _to;
      _to = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'FX Converter',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh rates',
          onPressed: () => context.read<FxCubit>().refresh(base: _from),
        ),
      ],
      body: BlocBuilder<FxCubit, FxState>(
        builder: (context, state) {
          final codes = {
            for (final r in state.rates) r.quote,
            _from,
            _to,
          }.toList()..sort();
          final result = context.read<FxCubit>().convert(
            amount: _amount,
            from: _from,
            to: _to,
          );
          final rateLine = state.rates.where((r) => r.base == _from && r.quote == _to).map((r) => r.rate).firstOrNull;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              const SectionHeader(
                title: 'Convert',
                uppercase: true,
                tone: SectionHeaderTone.primary,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _amountCtrl,
                      label: 'Amount',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _amount = double.tryParse(v) ?? 0),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CurrencyDropdown(
                            label: 'From',
                            value: _from,
                            options: codes,
                            onChanged: (v) {
                              if (v != null) setState(() => _from = v);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: IconButton.filledTonal(
                            icon: const Icon(Icons.swap_horiz),
                            tooltip: 'Swap',
                            onPressed: _swap,
                          ),
                        ),
                        Expanded(
                          child: _CurrencyDropdown(
                            label: 'To',
                            value: _to,
                            options: codes,
                            onChanged: (v) {
                              if (v != null) setState(() => _to = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GradientHero.brand(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.currency(_amount, code: _from),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      Formatters.currency(result, code: _to),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    if (rateLine != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '1 $_from = ${rateLine.toStringAsFixed(4)} $_to',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (state.lastUpdated != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last updated ${Formatters.date(state.lastUpdated!)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(
                title: 'Available rates',
                uppercase: true,
                tone: SectionHeaderTone.primary,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.rates.isEmpty)
                const AppCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(child: Text('No rates yet')),
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < state.rates.where((r) => r.base == _from).length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        Builder(
                          builder: (_) {
                            final r = state.rates.where((r) => r.base == _from).elementAt(i);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: context.tokens.brandSubtle,
                                child: Text(
                                  r.quote.substring(
                                    0,
                                    r.quote.length.clamp(0, 3),
                                  ),
                                  style: TextStyle(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              title: Text(
                                '1 ${r.base} = ${r.rate.toStringAsFixed(4)} ${r.quote}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                Formatters.date(r.updatedAt),
                                style: TextStyle(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
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

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: onChanged,
    );
  }
}
