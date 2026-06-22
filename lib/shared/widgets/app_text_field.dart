import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';

/// A reusable text input with label, validation, and password obfuscation.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.maxLines = 1,
    this.initialValue,
    this.dense = false,
    this.inputFormatters,
    this.validator,
    this.autovalidateMode,
  }) : assert(
         controller != null || initialValue != null,
         'Provide either controller or initialValue',
       );

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final String? initialValue;
  final bool dense;
  final List<TextInputFormatter>? inputFormatters;

  /// Optional form validator. When provided, the underlying input is a
  /// [TextFormField] so it participates in `Form.validate()` calls.
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final controller =
        this.controller ?? TextEditingController(text: initialValue);
    final tt = context.textTheme;
    final field = TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      maxLines: obscure ? 1 : maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: autovalidateMode,
      style: tt.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        errorText: error,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
        isDense: dense,
        contentPadding: dense
            ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              )
            : null,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        field,
      ],
    );
  }
}

class AppDividerWithLabel extends StatelessWidget {
  const AppDividerWithLabel(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
