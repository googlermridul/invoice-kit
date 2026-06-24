import 'package:flutter/material.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';

/// A two-column key/value row.
///
/// Replaces the duplicated `_kv` helper that was hand-built in
/// onboarding, client detail, invoice detail, and quote detail.
class KvRow extends StatelessWidget {
  const KvRow({
    required this.label,
    required this.value,
    super.key,
    this.bold = false,
    this.labelColor,
    this.valueColor,
    this.semanticValue,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? labelColor;
  final Color? valueColor;
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final style = bold ? tt.titleMedium : tt.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: style?.copyWith(
                color: labelColor ?? context.colors.onSurfaceVariant,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              semanticsLabel: semanticValue,
              style: style?.copyWith(
                color: valueColor,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
