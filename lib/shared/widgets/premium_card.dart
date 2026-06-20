import 'package:flutter/material.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
    this.cta,
    this.onTap,
    this.trialDays,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? cta;
  final VoidCallback? onTap;
  final int? trialDays;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.premiumGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trialDays != null
                        ? '$subtitle · $trialDays day${trialDays == 1 ? '' : 's'} left'
                        : subtitle,
                    style: text.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (cta != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  cta!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
