import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_boilerplate/core/theme/app_spacing.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: AppSpacing.lg),
              Text('Route not found', style: context.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error?.toString() ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
