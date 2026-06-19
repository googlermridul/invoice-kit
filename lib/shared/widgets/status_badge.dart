import 'package:flutter/material.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.color, super.key, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceStatusBadge extends StatelessWidget {
  const InvoiceStatusBadge(this.status, {super.key});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return StatusBadge(label: status.label, color: color);
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
  const QuoteStatusBadge(this.status, {super.key});
  final QuoteStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return StatusBadge(label: status.label, color: color);
  }

  static Color _color(QuoteStatus s) => switch (s) {
    QuoteStatus.draft => AppColors.statusDraft,
    QuoteStatus.sent => AppColors.statusSent,
    QuoteStatus.accepted => AppColors.statusAccepted,
    QuoteStatus.declined => AppColors.statusDeclined,
    QuoteStatus.expired => AppColors.statusExpired,
  };
}
