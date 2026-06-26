import 'package:flutter/material.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/features/invoices/domain/entities/pdf_template.dart';

/// Style data for rendering a per-invoice header that visually mirrors one
/// of the built-in PDF templates. Pure presentation — no PDF rendering
/// involved. Keeps the on-screen detail page in lockstep with the exported
/// PDF for the user.
class TemplateStyle {
  const TemplateStyle({
    required this.id,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.elevated,
    required this.serif,
    required this.label,
  });

  final String id;
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color elevated;
  final bool serif;
  final String label;

  static TemplateStyle forId(String? id) =>
      switch (id ?? PdfTemplateIds.classic) {
        PdfTemplateIds.minimal => const TemplateStyle(
          id: PdfTemplateIds.minimal,
          accent: Color(0xFF0F172A),
          onAccent: Color(0xFFFFFFFF),
          background: Color(0xFFFAFAF7),
          elevated: Color(0xFFFFFFFF),
          serif: false,
          label: 'Minimal',
        ),
        PdfTemplateIds.modern => const TemplateStyle(
          id: PdfTemplateIds.modern,
          accent: Color(0xFF0EA5E9),
          onAccent: Color(0xFFFFFFFF),
          background: Color(0xFF0F172A),
          elevated: Color(0xFF1E293B),
          serif: false,
          label: 'Modern',
        ),
        PdfTemplateIds.elegant => const TemplateStyle(
          id: PdfTemplateIds.elegant,
          accent: Color(0xFF8B5E34),
          onAccent: Color(0xFFFFFFFF),
          background: Color(0xFFFBF7F1),
          elevated: Color(0xFFFFFFFF),
          serif: true,
          label: 'Elegant',
        ),
        PdfTemplateIds.bold => const TemplateStyle(
          id: PdfTemplateIds.bold,
          accent: Color(0xFFE11D48),
          onAccent: Color(0xFFFFFFFF),
          background: Color(0xFFFFFFFF),
          elevated: Color(0xFFFFFFFF),
          serif: false,
          label: 'Bold Business',
        ),
        PdfTemplateIds.service => const TemplateStyle(
          id: PdfTemplateIds.service,
          accent: Color(0xFF15803D),
          onAccent: Color(0xFFFFFFFF),
          background: Color(0xFFF7FEE7),
          elevated: Color(0xFFFFFFFF),
          serif: false,
          label: 'Service Freelancer',
        ),
        _ => const TemplateStyle(
          id: PdfTemplateIds.classic,
          accent: Color(0xFF4338CA),
          onAccent: Color(0xFFFFFFFF),
          background: Color(0xFFFFFFFF),
          elevated: Color(0xFFFFFFFF),
          serif: false,
          label: 'Classic',
        ),
      };
}

/// Renders a header block at the top of the invoice detail screen that
/// previews the look-and-feel of the selected PDF template.
class TemplatePreviewHeader extends StatelessWidget {
  const TemplatePreviewHeader({
    required this.style,
    required this.title,
    required this.subtitle,
    this.rightLabel,
    this.rightValue,
    super.key,
  });

  final TemplateStyle style;
  final String title;
  final String subtitle;
  final String? rightLabel;
  final String? rightValue;

  @override
  Widget build(BuildContext context) {
    final accentOnBg = style.background.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
    final subtitleColor = accentOnBg.withValues(alpha: 0.75);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: style.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 56,
            decoration: BoxDecoration(
              color: style.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentOnBg,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    fontFamily: style.serif ? 'serif' : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (rightLabel != null && rightValue != null) ...[
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rightLabel!,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rightValue!,
                  style: TextStyle(
                    color: accentOnBg,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
