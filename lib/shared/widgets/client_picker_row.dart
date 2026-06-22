import 'package:flutter/material.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';
import 'package:invoice_kit/shared/widgets/searchable_picker_sheet.dart';

/// Tappable row that opens a bottom sheet to pick a client.
class ClientPickerRow extends StatelessWidget {
  const ClientPickerRow({
    required this.label,
    required this.selectedName,
    required this.options,
    required this.onSelected,
    super.key,
    this.emptyLabel = 'Tap to choose',
  });

  final String label;
  final String? selectedName;
  final List<({String id, String name, String? subtitle})> options;
  final String emptyLabel;
  final ValueChanged<String> onSelected;

  Future<void> _open(BuildContext context) async {
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a client first.')),
      );
      return;
    }
    final id = await SearchablePickerSheet.show<String>(
      context: context,
      title: label,
      hint: 'Search clients',
      options: options
          .map(
            (c) => SearchableOption<String>(
              value: c.id,
              label: c.name,
              subtitle: c.subtitle,
              searchTerms: c.subtitle == null ? null : [c.subtitle!],
            ),
          )
          .toList(),
      leadingBuilder: (o) => CircleAvatar(
        radius: 14,
        backgroundColor: context.tokens.brandSubtle,
        child: Text(
          o.label.isEmpty ? '?' : o.label.characters.first.toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    if (id != null) {
      onSelected(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadius.md,
      onTap: () => _open(context),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: context.colors.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedName ?? emptyLabel,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selectedName == null ? context.colors.onSurfaceVariant : context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: context.colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
