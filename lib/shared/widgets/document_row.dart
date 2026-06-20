import 'package:flutter/material.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';

/// A reusable list row for documents (invoices / quotes / recurring).
///
/// Renders a number, client name, status chip (or trailing widget),
/// and a bold total. Used by the lists and dashboard recents.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    super.key,
    this.statusChip,
    this.trailing,
    this.onTap,
    this.amountTrailing,
  });

  final String title;
  final String subtitle;
  final double amount;
  final String currency;
  final Widget? statusChip;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? amountTrailing;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final right = [
      ?statusChip,
      ?trailing,
    ];
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (right.isNotEmpty) ...right,
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: tt.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  Formatters.currency(amount, code: currency),
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              ?amountTrailing,
            ],
          ),
        ],
      ),
    );
  }
}
