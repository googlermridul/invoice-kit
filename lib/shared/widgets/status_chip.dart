import 'package:flutter/material.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart';

/// A polished pill-shaped status chip. Use the typed wrappers below
/// when you want automatic colour mapping.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.color,
    super.key,
    this.icon,
    this.size = StatusChipSize.md,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final StatusChipSize size;

  @override
  Widget build(BuildContext context) {
    final padding = switch (size) {
      StatusChipSize.sm => const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      StatusChipSize.md => const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    };
    final fontSize = switch (size) {
      StatusChipSize.sm => 10.0,
      StatusChipSize.md => 11.0,
    };
    final iconSize = switch (size) {
      StatusChipSize.sm => 10.0,
      StatusChipSize.md => 12.0,
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: iconSize),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusChipSize { sm, md }

class InvoiceStatusBadge extends StatelessWidget {
  const InvoiceStatusBadge(this.status, {super.key, this.size});
  final InvoiceStatus status;
  final StatusChipSize? size;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: status.label,
      color: _color(status),
      size: size ?? StatusChipSize.md,
    );
  }

  static Color _color(InvoiceStatus s) => switch (s) {
    InvoiceStatus.draft => AppColors.statusDraft,
    InvoiceStatus.sent => AppColors.statusSent,
    InvoiceStatus.paid => AppColors.statusPaid,
    InvoiceStatus.overdue => AppColors.statusOverdue,
    InvoiceStatus.cancelled => AppColors.statusCancelled,
  };
}

class QuoteStatusBadge extends StatelessWidget {
  const QuoteStatusBadge(this.status, {super.key, this.size});
  final QuoteStatus status;
  final StatusChipSize? size;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: status.label,
      color: _color(status),
      size: size ?? StatusChipSize.md,
    );
  }

  static Color _color(QuoteStatus s) => switch (s) {
    QuoteStatus.draft => AppColors.statusDraft,
    QuoteStatus.sent => AppColors.statusSent,
    QuoteStatus.accepted => AppColors.statusAccepted,
    QuoteStatus.declined => AppColors.statusDeclined,
    QuoteStatus.expired => AppColors.statusExpired,
  };
}

// Backwards-compatible alias kept for old imports.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.color,
    super.key,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: label, color: color, icon: icon);
}
