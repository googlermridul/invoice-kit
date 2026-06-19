import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart' show SubscriptionPlan;
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionPlan _selected = SubscriptionPlan.yearly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                _Header(state: state),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Text(
                        'Unlock every feature',
                        style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        state.isTrialing
                            ? 'Your free trial ends in ${state.trialDaysRemaining} day${state.trialDaysRemaining == 1 ? '' : 's'}. Pick a plan to keep using InvoiceKit.'
                            : 'Pick a plan to continue. No backend, all data stays on this device.',
                        style: context.textTheme.bodyMedium?.copyWith(color: context.colors.outline),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _PlanCard(
                        plan: SubscriptionPlan.monthly,
                        price: r'$4.99',
                        period: 'per month',
                        highlight: 'Flexible',
                        selected: _selected == SubscriptionPlan.monthly,
                        onTap: () => setState(() => _selected = SubscriptionPlan.monthly),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PlanCard(
                        plan: SubscriptionPlan.yearly,
                        price: r'$39.99',
                        period: 'per year',
                        highlight: 'Save 33%',
                        selected: _selected == SubscriptionPlan.yearly,
                        onTap: () => setState(() => _selected = SubscriptionPlan.yearly),
                        ribbon: 'Best value',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ..._benefits.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(b.icon, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: Text(b.text)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: TextButton(
                          onPressed: state.status == SubscriptionStatusX.restoring
                              ? null
                              : () => context.read<SubscriptionBloc>().add(const SubscriptionRestored()),
                          child: const Text('Restore purchase'),
                        ),
                      ),
                    ],
                  ),
                ),
                _Footer(
                  selected: _selected,
                  state: state,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});
  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      decoration: const BoxDecoration(gradient: AppColors.premiumGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'InvoiceKit Premium',
                style: context.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.isTrialing)
            Text(
              'Free trial · ${state.trialDaysRemaining} days remaining',
              style: const TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.price,
    required this.period,
    required this.highlight,
    required this.selected,
    required this.onTap,
    this.ribbon,
  });

  final SubscriptionPlan plan;
  final String price;
  final String period;
  final String highlight;
  final bool selected;
  final VoidCallback onTap;
  final String? ribbon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : context.colors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: selected,
                  onChanged: (_) => onTap(),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan == SubscriptionPlan.yearly ? 'Yearly' : 'Monthly',
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(highlight, style: TextStyle(color: context.colors.outline)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(period, style: TextStyle(color: context.colors.outline)),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (ribbon != null)
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                ribbon!,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

class _Benefit {
  const _Benefit(this.icon, this.text);
  final IconData icon;
  final String text;
}

const _benefits = <_Benefit>[
  _Benefit(Icons.receipt_long_rounded, 'Unlimited invoices, quotes and clients'),
  _Benefit(Icons.repeat_rounded, 'Recurring billing with auto-generation'),
  _Benefit(Icons.picture_as_pdf_outlined, '6 polished PDF templates'),
  _Benefit(Icons.bar_chart_rounded, 'Revenue reports and trends'),
  _Benefit(Icons.cloud_sync_outlined, 'Encrypted backup and restore'),
  _Benefit(Icons.swap_horiz_rounded, 'Built-in FX converter'),
];

class _Footer extends StatelessWidget {
  const _Footer({required this.selected, required this.state});
  final SubscriptionPlan selected;
  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: state.status == SubscriptionStatusX.purchasing
                  ? 'Activating…'
                  : 'Continue with ${selected == SubscriptionPlan.yearly ? 'Yearly' : 'Monthly'}',
              onPressed: state.status == SubscriptionStatusX.purchasing
                  ? null
                  : () async {
                      context.read<SubscriptionBloc>().add(SubscriptionPlanPurchased(selected));
                      await Future<void>.delayed(const Duration(milliseconds: 400));
                      if (context.mounted) context.go('/dashboard');
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Payment is processed via a dummy endpoint in this build. Real billing wires in later.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(color: context.colors.outline),
            ),
          ],
        ),
      ),
    );
  }
}
