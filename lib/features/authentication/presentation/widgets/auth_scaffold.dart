import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_boilerplate/core/theme/app_spacing.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.title, required this.subtitle, required this.child, super.key});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: context.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: context.textTheme.bodyMedium?.copyWith(color: context.colors.outline),
              ),
              const SizedBox(height: AppSpacing.xxl),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
