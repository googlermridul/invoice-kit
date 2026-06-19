import 'package:flutter/material.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          ?trailing,
        ],
      ),
    );
  }
}
