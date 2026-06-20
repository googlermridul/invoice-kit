import 'package:flutter/material.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';

/// Tone of a [SectionHeader] for caps-style headers.
enum SectionHeaderTone { neutral, primary }

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.trailing,
    this.padding,
    this.uppercase = false,
    this.tone = SectionHeaderTone.neutral,
  });
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool uppercase;
  final SectionHeaderTone tone;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final color = tone == SectionHeaderTone.primary
        ? context.colors.primary
        : null;
    final style = uppercase
        ? tt.labelSmall?.copyWith(
            color: color ?? context.colors.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          )
        : tt.titleMedium?.copyWith(color: color);

    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
      child: Row(
        children: [
          Expanded(
            child: Text(uppercase ? title.toUpperCase() : title, style: style),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
