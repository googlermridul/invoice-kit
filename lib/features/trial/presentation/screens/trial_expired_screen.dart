import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/router/app_routes.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/shared/widgets/buttons.dart';

/// Shown when the trial has expired and the user is not logged in.
/// Routes to auth, then to subscription.
class TrialExpiredScreen extends StatelessWidget {
  const TrialExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_off_outlined, size: 72),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your free trial has ended',
                style: context.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in or create an account to continue using InvoiceKit. '
                'Choose a plan to unlock every premium feature.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'Sign in or sign up',
                onPressed: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'View subscription plans',
                onPressed: () => context.go(AppRoutes.subscription),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
