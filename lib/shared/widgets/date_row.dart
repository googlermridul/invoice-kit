import 'package:flutter/material.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/utils/formatters.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';

/// Tappable row that opens a date picker. Used in invoice/quote edit forms.
class DateRow extends StatelessWidget {
  const DateRow({
    required this.label,
    required this.value,
    required this.onPicked,
    super.key,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadius.md,
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2010),
          lastDate: DateTime(2100),
        );
        if (d != null) onPicked(d);
      },
      child: Row(
        children: [
          Icon(
            Icons.event_outlined,
            color: context.colors.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: context.textTheme.bodyMedium),
          const Spacer(),
          Text(
            Formatters.date(value),
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
