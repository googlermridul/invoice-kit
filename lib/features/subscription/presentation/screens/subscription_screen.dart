import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/app_routes.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/core/widgets/widgets.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart'
    show SubscriptionPlan;
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:invoice_kit/shared/widgets/buttons.dart';

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
      backgroundColor: context.colors.surface,
      body: BlocBuilder<SubscriptionBloc, SubscriptionBlocState>(
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                _Header(state: state),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _PriceBlock(
                        selected: _selected,
                        isTrialing: state.isTrialing,
                        trialDaysRemaining: state.trialDaysRemaining,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _PlanToggle(
                        selected: _selected,
                        onChanged: (p) => setState(() => _selected = p),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const _BenefitsSection(),
                      const SizedBox(height: AppSpacing.xl),
                      Center(
                        child: TextButton(
                          onPressed:
                              state.status == SubscriptionStatusX.restoring
                              ? null
                              : () => context.read<SubscriptionBloc>().add(
                                  const SubscriptionRestored(),
                                ),
                          child: Text(
                            state.status == SubscriptionStatusX.restoring
                                ? 'Restoring…'
                                : 'Restore purchase',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                _Footer(selected: _selected, state: state),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Premium gradient hero with branding and optional trial badge.
class _Header extends StatelessWidget {
  const _Header({required this.state});
  final SubscriptionBlocState state;

  @override
  Widget build(BuildContext context) {
    return GradientHero.premium(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      radius: 0,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'InvoiceKit',
                      style: context.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Premium',
                      style: context.textTheme.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.workspace_premium_rounded, size: 24),
                tooltip: 'Close',
              ),
            ],
          ),
          if (state.isTrialing) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Free trial · ${state.trialDaysRemaining} day${state.trialDaysRemaining == 1 ? '' : 's'} left',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Large price display that reacts to the selected plan.
class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.selected,
    required this.isTrialing,
    required this.trialDaysRemaining,
  });

  final SubscriptionPlan selected;
  final bool isTrialing;
  final int trialDaysRemaining;

  @override
  Widget build(BuildContext context) {
    final isYearly = selected == SubscriptionPlan.yearly;
    final price = isYearly ? r'$39.99' : r'$4.99';
    final period = isYearly ? '/year' : '/month';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unlock every feature',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isTrialing
                ? 'Your trial ends in $trialDaysRemaining day${trialDaysRemaining == 1 ? '' : 's'}. Pick a plan to keep going.'
                : 'Pick a plan to continue. No backend — all data stays on this device.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  price,
                  key: ValueKey(price),
                  style: context.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                period,
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Segmented toggle for switching between Monthly and Yearly.
class _PlanToggle extends StatelessWidget {
  const _PlanToggle({required this.selected, required this.onChanged});

  final SubscriptionPlan selected;
  final ValueChanged<SubscriptionPlan> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: 'Monthly',
              sublabel: r'$4.99/mo',
              selected: selected == SubscriptionPlan.monthly,
              onTap: () => onChanged(SubscriptionPlan.monthly),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _ToggleOption(
              label: 'Yearly',
              sublabel: r'$3.33/mo',
              badge: 'Save 33%',
              selected: selected == SubscriptionPlan.yearly,
              onTap: () => onChanged(SubscriptionPlan.yearly),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: tokens.motionFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? tokens.brandSubtle : context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? context.colors.primary : tokens.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? context.colors.primary
                          : context.colors.onSurface,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: tokens.motionFast,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? context.colors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? context.colors.primary
                          : tokens.borderStrong,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          HugeIconsStroke.tick02,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              sublabel,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge!,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Benefit {
  const _Benefit(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
}

const _benefits = <_Benefit>[
  _Benefit(
    Icons.receipt_long_rounded,
    'Unlimited documents',
    'Invoices, quotes and clients without limits',
  ),
  _Benefit(
    Icons.repeat_rounded,
    'Recurring billing',
    'Auto-generation of recurring invoices',
  ),
  _Benefit(
    Icons.picture_as_pdf_outlined,
    'PDF templates',
    '6 polished, professional templates',
  ),
  _Benefit(
    Icons.bar_chart_rounded,
    'Revenue insights',
    'Reports and trends at a glance',
  ),
  _Benefit(
    Icons.cloud_sync_outlined,
    'Encrypted backup',
    'Secure backup and restore on device',
  ),
  _Benefit(
    Icons.swap_horiz_rounded,
    'FX converter',
    'Built-in multi-currency conversion',
  ),
];

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'What you get',
            uppercase: true,
            tone: SectionHeaderTone.primary,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          ..._benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.tokens.brandSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      b.icon,
                      color: context.colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.title,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.subtitle,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.selected, required this.state});
  final SubscriptionPlan selected;
  final SubscriptionBlocState state;

  @override
  Widget build(BuildContext context) {
    final isPurchasing = state.status == SubscriptionStatusX.purchasing;
    final isYearly = selected == SubscriptionPlan.yearly;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.tokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: isPurchasing
                  ? 'Activating…'
                  : 'Continue with ${isYearly ? 'Yearly' : 'Monthly'}',
              icon: isPurchasing ? null : Icons.arrow_forward_rounded,
              onPressed: isPurchasing
                  ? null
                  : () async {
                      context.read<SubscriptionBloc>().add(
                        SubscriptionPlanPurchased(selected),
                      );
                      await Future<void>.delayed(
                        const Duration(milliseconds: 400),
                      );
                      if (context.mounted) context.go(AppRoutes.dashboard);
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Payment is processed via a dummy endpoint in this build. Real billing wires in later.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
