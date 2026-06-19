import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/features/fx/presentation/bloc/fx_cubit.dart';

class FxScreen extends StatefulWidget {
  const FxScreen({super.key});

  @override
  State<FxScreen> createState() => _FxScreenState();
}

class _FxScreenState extends State<FxScreen> {
  String _from = 'USD';
  String _to = 'EUR';
  double _amount = 100;

  @override
  Future<void> initState() async {
    super.initState();
    await context.read<FxCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FX Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FxCubit>().refresh(base: _from),
          ),
        ],
      ),
      body: BlocBuilder<FxCubit, FxState>(
        builder: (context, state) {
          final codes = {for (final r in state.rates) r.quote, _from, _to}.toList()..sort();
          final result = context.read<FxCubit>().convert(
            amount: _amount,
            from: _from,
            to: _to,
          );
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => setState(() => _amount = double.tryParse(v) ?? 0),
                controller: TextEditingController(text: _amount == 0 ? '' : _amount.toString()),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _from,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                      ),
                      items: codes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _from = v);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () {
                      setState(() {
                        final t = _from;
                        _from = _to;
                        _to = t;
                      });
                    },
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _to,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                      ),
                      items: codes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _to = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colors.primary,
                      context.colors.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.currency(_amount, code: _from),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.currency(result, code: _to),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                    if (state.lastUpdated != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Last updated ${Formatters.date(state.lastUpdated!)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Available rates', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (state.rates.isEmpty) const EmptyState(icon: Icons.swap_horiz, title: 'No rates yet'),
              ...state.rates
                  .where((r) => r.base == _from)
                  .map(
                    (r) => ListTile(
                      title: Text('1 ${r.base} = ${r.rate.toStringAsFixed(4)} ${r.quote}'),
                      subtitle: Text(Formatters.date(r.updatedAt)),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
