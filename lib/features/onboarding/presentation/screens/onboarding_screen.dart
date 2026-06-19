import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  // final int _index = 0;

  @override
  void initState() {
    super.initState();
    context.read<OnboardingBloc>().add(const OnboardingStarted());
  }

  Future<void> _setStep(int step) async {
    context.read<OnboardingBloc>().add(OnboardingStepChanged(step));
    await _pageController.animateToPage(step, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == OnboardingStatus.completed) {
          // context.go('/dashboard');
          context.go(RoutePaths.dashboard);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _StepIndicator(
                  step: state.step,
                  total: 6,
                  onSkip: () {
                    context.read<OnboardingBloc>().add(const OnboardingCompleted());
                  },
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => context.read<OnboardingBloc>().add(OnboardingStepChanged(i)),
                    children: [
                      _IntroStep(onNext: () => _setStep(1)),
                      _UserNameStep(
                        value: state.userName,
                        onChanged: (v) => context.read<OnboardingBloc>().add(OnboardingUserNameChanged(v)),
                        onNext: () => _setStep(2),
                      ),
                      _BusinessStep(
                        businessName: state.businessName,
                        currency: state.currency,
                        onBusinessName: (v) => context.read<OnboardingBloc>().add(OnboardingBusinessNameChanged(v)),
                        onCurrency: (v) => context.read<OnboardingBloc>().add(OnboardingCurrencyChanged(v)),
                        onNext: () => _setStep(3),
                      ),
                      _TaxStep(
                        taxId: state.taxId,
                        paymentTerms: state.paymentTerms,
                        onTaxId: (v) => context.read<OnboardingBloc>().add(OnboardingTaxIdChanged(v)),
                        onTerms: (v) => context.read<OnboardingBloc>().add(OnboardingPaymentTermsChanged(v)),
                        onNext: () => _setStep(4),
                      ),
                      _ThemeStep(
                        value: state.themeModeName,
                        onChanged: (v) => context.read<OnboardingBloc>().add(OnboardingThemeChanged(v)),
                        onNext: () => _setStep(5),
                      ),
                      _ReviewStep(
                        userName: state.userName,
                        businessName: state.businessName,
                        currency: state.currency,
                        paymentTerms: state.paymentTerms,
                        taxId: state.taxId,
                        onBack: () => _setStep(4),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: state.step == 5
                      ? PrimaryButton(
                          label: state.status == OnboardingStatus.saving ? 'Setting up…' : 'Start 14-day free trial',
                          onPressed: state.status == OnboardingStatus.saving
                              ? null
                              : () => context.read<OnboardingBloc>().add(const OnboardingCompleted()),
                        )
                      : Row(
                          children: [
                            if (state.step > 0)
                              Expanded(
                                child: SecondaryButton(
                                  label: 'Back',
                                  onPressed: () => _setStep(state.step - 1),
                                ),
                              ),
                            if (state.step > 0) const SizedBox(width: AppSpacing.md),
                            Expanded(
                              flex: 2,
                              child: PrimaryButton(
                                label: 'Continue',
                                onPressed: state.canProceed ? () => _setStep(state.step + 1) : null,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.total, required this.onSkip});
  final int step;
  final int total;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (step + 1) / total,
                minHeight: 6,
                color: AppColors.primary,
                backgroundColor: context.colors.outlineVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          TextButton(
            onPressed: step == 0 ? null : onSkip,
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 60),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Welcome to InvoiceKit', style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Send invoices, quotes and recurring bills from one place. Local-first, polished, fast.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(color: context.colors.outline),
          ),
        ],
      ),
    );
  }
}

class _UserNameStep extends StatelessWidget {
  const _UserNameStep({
    required this.value,
    required this.onChanged,
    required this.onNext,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'What should we call you?',
            style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your name appears on invoices and quotes.',
            style: context.textTheme.bodyMedium?.copyWith(color: context.colors.outline),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Your name',
            hint: 'Jane Doe',
            initialValue: value,
            onChanged: onChanged,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }
}

class _BusinessStep extends StatelessWidget {
  const _BusinessStep({
    required this.businessName,
    required this.currency,
    required this.onBusinessName,
    required this.onCurrency,
    required this.onNext,
  });

  final String businessName;
  final String currency;
  final ValueChanged<String> onBusinessName;
  final ValueChanged<String> onCurrency;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('Your business', style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You can change these later in Settings.',
            style: context.textTheme.bodyMedium?.copyWith(color: context.colors.outline),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Business name',
            hint: 'Acme Studio',
            initialValue: businessName,
            onChanged: onBusinessName,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: currency,
            decoration: const InputDecoration(
              labelText: 'Default currency',
              border: OutlineInputBorder(),
            ),
            items: CurrencyCodes.common
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text('${CurrencyCodes.symbolOf(c)}  $c'),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onCurrency(v);
            },
          ),
        ],
      ),
    );
  }
}

class _TaxStep extends StatelessWidget {
  const _TaxStep({
    required this.taxId,
    required this.paymentTerms,
    required this.onTaxId,
    required this.onTerms,
    required this.onNext,
  });

  final String taxId;
  final String paymentTerms;
  final ValueChanged<String> onTaxId;
  final ValueChanged<String> onTerms;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('Tax & payment terms', style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Optional. Both are editable per document.',
            style: context.textTheme.bodyMedium?.copyWith(color: context.colors.outline),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Tax ID / VAT / GST',
            hint: '123456789',
            initialValue: taxId,
            onChanged: onTaxId,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Default payment terms',
            hint: 'Payment due within 14 days.',
            initialValue: paymentTerms,
            onChanged: onTerms,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _ThemeStep extends StatelessWidget {
  const _ThemeStep({
    required this.value,
    required this.onChanged,
    required this.onNext,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('Choose your theme', style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.lg),
          ...['light', 'dark', 'system'].map(
            (mode) => RadioListTile<String>(
              value: mode,
              groupValue: value,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              title: Text(mode[0].toUpperCase() + mode.substring(1)),
              subtitle: Text(mode == 'system' ? 'Match device setting' : 'Always use $mode mode'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.userName,
    required this.businessName,
    required this.currency,
    required this.paymentTerms,
    required this.taxId,
    required this.onBack,
  });

  final String userName;
  final String businessName;
  final String currency;
  final String paymentTerms;
  final String taxId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text('Almost ready', style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'A 14-day free trial unlocks every feature. No credit card required.',
            style: context.textTheme.bodyMedium?.copyWith(color: context.colors.outline),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _kv('Your name', userName.isEmpty ? '—' : userName),
                _kv('Business', businessName.isEmpty ? '—' : businessName),
                _kv('Currency', '$currency ${CurrencyCodes.symbolOf(currency)}'),
                _kv('Tax ID', taxId.isEmpty ? '—' : taxId),
                _kv('Payment terms', paymentTerms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
