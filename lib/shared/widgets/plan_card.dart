import 'package:flutter/material.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';

/// A selectable plan card used in the subscription / paywall screen.
class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.name,
    required this.price,
    required this.period,
    required this.benefits,
    super.key,
    this.selected = false,
    this.recommended = false,
    this.onTap,
  });

  final String name;
  final String price;
  final String period;
  final List<String> benefits;
  final bool selected;
  final bool recommended;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return AppCard(
      onTap: onTap,
      variant: selected ? AppCardVariant.tinted : AppCardVariant.outlined,
      radius: AppRadius.xl,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? context.colors.primary
                            : context.colors.onSurface,
                      ),
                    ),
                  ),
                  _RadioDot(selected: selected),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: tt.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: selected
                          ? context.colors.primary
                          : context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      period,
                      style: tt.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: selected
                            ? context.colors.primary
                            : context.colors.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(b, style: tt.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (recommended)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'RECOMMENDED',
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? context.colors.primary : Colors.transparent,
        border: Border.all(
          color: selected
              ? context.colors.primary
              : context.colors.onSurfaceVariant,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
