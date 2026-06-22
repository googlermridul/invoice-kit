import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';

/// A polished search input with a search icon prefix and a clear button.
class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;
        return TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          textInputAction: TextInputAction.search,
          style: context.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: context.colors.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(HugeIconsStroke.cancel01, size: 18),
                    color: context.colors.onSurfaceVariant,
                    onPressed: () {
                      controller.clear();
                      onClear?.call();
                      onChanged?.call('');
                    },
                  )
                : null,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            filled: true,
            fillColor: context.tokens.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: context.colors.primary, width: 1.4),
            ),
          ),
        );
      },
    );
  }
}
