import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/route_paths.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/widgets/gradient_hero.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:invoice_kit/features/trial/domain/repositories/trial_repository.dart';
import 'package:invoice_kit/features/trial/presentation/cubit/trial_cubit.dart';
import 'package:invoice_kit/shared/widgets/buttons.dart';

/// Welcome screen reached from [IntroScreen].
///
/// Two CTAs:
///
/// 1. **Already a premium user? Login** — does NOT start a trial.
///    Sets `introOnboardingCompleted = true` so the guard stops forcing
///    the intro flow, then routes to `/login`.
///
/// 2. **Start with free trial** — starts the trial via [TrialRepository],
///    mirrors `trial_started_at` into [LocalStorageService], refreshes
///    [SubscriptionBloc] + [TrialCubit], sets the intro-complete flag,
///    then routes to `/onboarding` (the setup wizard).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.trialRepository,
    this.localStorage,
    this.subscriptionBloc,
    this.trialCubit,
  });

  /// Injectable seams for unit tests. Production code resolves them
  /// from GetIt on demand.
  final TrialRepository? trialRepository;
  final LocalStorageService? localStorage;
  final SubscriptionBloc? subscriptionBloc;
  final TrialCubit? trialCubit;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _busy = false;

  TrialRepository get _trials =>
      widget.trialRepository ?? sl<TrialRepository>();

  LocalStorageService get _prefs =>
      widget.localStorage ?? sl<LocalStorageService>();

  SubscriptionBloc? get _subscriptionBloc =>
      widget.subscriptionBloc ??
      (sl.isRegistered<SubscriptionBloc>() ? sl<SubscriptionBloc>() : null);

  TrialCubit? get _trialCubit =>
      widget.trialCubit ??
      (sl.isRegistered<TrialCubit>() ? sl<TrialCubit>() : null);

  Future<void> _onLoginPressed() async {
    await _prefs.setBool(StorageKeys.introOnboardingCompleted, true);
    if (!mounted) return;
    context.go(RoutePaths.login);
  }

  Future<void> _onStartTrialPressed() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final trial = await _trials.startTrial(now: now);
      await _prefs.setString(
        StorageKeys.trialStartedAt,
        trial.startedAt.toIso8601String(),
      );
      // Back-compat mirror used by dashboard banners.
      await _prefs.setString(
        StorageKeys.trialStart,
        trial.startedAt.toIso8601String(),
      );
      await _prefs.setString(
        StorageKeys.trialEnd,
        trial.endsAt.toIso8601String(),
      );

      // Force the live blocs / cubits to refresh so the router guard
      // observes the new trial window on the very next navigation.
      _subscriptionBloc?.add(const SubscriptionStarted());
      await _trialCubit?.refresh();

      await _prefs.setBool(StorageKeys.introOnboardingCompleted, true);
      if (!mounted) return;
      context.go(RoutePaths.onboarding);
    } on Object catch (e) {
      if (!mounted) return;
      context.showSnackBar('Could not start trial: $e');
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: GradientHero.brand(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  radius: 32,
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Welcome to InvoiceKit',
                textAlign: TextAlign.center,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Send invoices, quotes and recurring bills from one place. '
                'Local-first, polished, fast.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: _busy ? 'Starting…' : 'Start with free trial',
                onPressed: _busy ? null : _onStartTrialPressed,
                loading: _busy,
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'Already a premium user? Login',
                onPressed: _onLoginPressed,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _deviceLine(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _deviceLine() {
    if (kIsWeb) return 'Web · ${defaultTargetPlatform.name}';
    try {
      return '${Platform.operatingSystem} · ${Platform.operatingSystemVersion}';
    } on Object {
      return defaultTargetPlatform.name;
    }
  }
}
