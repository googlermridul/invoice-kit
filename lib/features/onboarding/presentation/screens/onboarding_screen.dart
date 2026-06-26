import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/core/theme/theme_bloc/theme_bloc.dart';
import 'package:invoice_kit/core/widgets/widgets.dart';
import 'package:invoice_kit/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:invoice_kit/shared/widgets/app_text_field.dart';
import 'package:invoice_kit/shared/widgets/buttons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    context.read<OnboardingBloc>().add(const OnboardingStarted());
  }

  Future<void> _setStep(int step) async {
    context.read<OnboardingBloc>().add(OnboardingStepChanged(step));
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == OnboardingStatus.completed) {
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
                    context.read<OnboardingBloc>().add(
                      const OnboardingCompleted(),
                    );
                  },
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => context.read<OnboardingBloc>().add(
                      OnboardingStepChanged(i),
                    ),
                    children: [
                      _IntroStep(onNext: () => _setStep(1)),
                      _UserNameStep(
                        value: state.userName,
                        onChanged: (v) => context.read<OnboardingBloc>().add(
                          OnboardingUserNameChanged(v),
                        ),
                        onNext: () => _setStep(2),
                      ),
                      _BusinessStep(
                        businessName: state.businessName,
                        currency: state.currency,
                        onBusinessName: (v) => context
                            .read<OnboardingBloc>()
                            .add(OnboardingBusinessNameChanged(v)),
                        onCurrency: (v) => context.read<OnboardingBloc>().add(
                          OnboardingCurrencyChanged(v),
                        ),
                        onNext: () => _setStep(3),
                      ),
                      _TaxStep(
                        taxId: state.taxId,
                        paymentTerms: state.paymentTerms,
                        onTaxId: (v) => context.read<OnboardingBloc>().add(
                          OnboardingTaxIdChanged(v),
                        ),
                        onTerms: (v) => context.read<OnboardingBloc>().add(
                          OnboardingPaymentTermsChanged(v),
                        ),
                        onNext: () => _setStep(4),
                      ),
                      _ThemeStep(
                        value: state.themeModeName,
                        onChanged: (v) => context.read<OnboardingBloc>().add(
                          OnboardingThemeChanged(v),
                        ),
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
                          label: state.status == OnboardingStatus.saving
                              ? 'Setting up…'
                              : 'Start 3-day free trial',
                          onPressed: state.status == OnboardingStatus.saving
                              ? null
                              : () => context.read<OnboardingBloc>().add(
                                  const OnboardingCompleted(),
                                ),
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
                            if (state.step > 0)
                              const SizedBox(width: AppSpacing.md),
                            Expanded(
                              flex: 2,
                              child: PrimaryButton(
                                label: 'Continue',
                                onPressed: state.canProceed
                                    ? () => _setStep(state.step + 1)
                                    : null,
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
  const _StepIndicator({
    required this.step,
    required this.total,
    required this.onSkip,
  });
  final int step;
  final int total;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (step + 1) / total,
                minHeight: 6,
                color: context.colors.primary,
                backgroundColor: context.tokens.surfaceMuted,
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
          GradientHero.brand(
            padding: const EdgeInsets.all(AppSpacing.xl),
            radius: 32,
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Welcome to InvoiceKit',
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Send invoices, quotes and recurring bills from one place. Local-first, polished, fast.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
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
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your name appears on invoices and quotes.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
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
          Text(
            'Your business',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You can change these later in Settings.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                AppTextField(
                  label: 'Business name',
                  hint: 'Acme Studio',
                  initialValue: businessName,
                  onChanged: onBusinessName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
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
          Text(
            'Tax & payment terms',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Optional. Both are editable per document.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                AppTextField(
                  label: 'Tax ID / VAT / GST',
                  hint: '123456789',
                  initialValue: taxId,
                  onChanged: onTaxId,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Default payment terms',
                  hint: 'Payment due within 3 days.',
                  initialValue: paymentTerms,
                  onChanged: onTerms,
                  maxLines: 3,
                ),
              ],
            ),
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
          Text(
            'Choose your theme',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _ThemeOption(
                        label: 'Match system',
                        subtitle: "Follow your system's theme setting",
                        value: ThemeMode.system,
                        groupValue: state.mode,
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                      ),
                      _ThemeOption(
                        label: 'Light',
                        subtitle: 'Always use light mode',
                        value: ThemeMode.light,
                        groupValue: state.mode,
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                      ),
                      _ThemeOption(
                        label: 'Dark',
                        subtitle: 'Always use dark mode',
                        value: ThemeMode.dark,
                        groupValue: state.mode,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.subtitle,
  });

  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      title: Text(label),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: (m) {
        if (m != null) context.read<ThemeBloc>().add(ThemeChanged(m));
      },
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
          Text(
            'Almost ready',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'A 3-day free trial unlocks every feature. No credit card required.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            variant: AppCardVariant.filled,
            child: Column(
              children: [
                KvRow(
                  label: 'Your name',
                  value: userName.isEmpty ? '—' : userName,
                ),
                KvRow(
                  label: 'Business',
                  value: businessName.isEmpty ? '—' : businessName,
                ),
                KvRow(
                  label: 'Currency',
                  value: '$currency ${CurrencyCodes.symbolOf(currency)}',
                ),
                KvRow(
                  label: 'Tax ID',
                  value: taxId.isEmpty ? '—' : taxId,
                ),
                KvRow(label: 'Payment terms', value: paymentTerms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
