import 'package:flutter/material.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/widgets/app_bottom_sheet.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';

/// Tappable row that opens a bottom sheet to pick a currency code.
class CurrencyPickerRow extends StatelessWidget {
  const CurrencyPickerRow({
    required this.selected,
    required this.options,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelected;

  Future<void> _open(BuildContext context) async {
    final code = await AppBottomSheet.show<String>(
      context: context,
      title: 'Pick a currency',
      children: options
          .map(
            (c) => ListTile(
              title: Text(c),
              trailing: c == selected ? Icon(Icons.check, color: context.colors.primary) : null,
              onTap: () => Navigator.pop(context, c),
            ),
          )
          .toList(),
    );
    if (code != null) onSelected(code);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadius.md,
      onTap: () => _open(context),
      child: Row(
        children: [
          Icon(
            Icons.attach_money,
            color: context.colors.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Currency',
              style: context.textTheme.bodyMedium,
            ),
          ),
          Text(
            selected,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right,
            color: context.colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
