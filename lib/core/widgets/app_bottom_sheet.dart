import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';

/// Convenience wrapper for a consistent bottom-sheet experience with
/// a sticky header, optional close button, and safe scrollable body.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.onClose,
    this.maxHeightFactor = 0.7,
    this.scrollable = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onClose;
  final double maxHeightFactor;
  final bool scrollable;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    String? subtitle,
    VoidCallback? onClose,
    double maxHeightFactor = 0.7,
    bool scrollable = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppBottomSheet(
        title: title,
        subtitle: subtitle,
        onClose: onClose,
        maxHeightFactor: maxHeightFactor,
        scrollable: scrollable,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: tt.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: Icon(HugeIconsStroke.cancel01, size: 18),
                  onPressed: () async {
                    await Navigator.of(context).maybePop();
                    onClose!();
                  },
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: scrollable
              ? SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
        ),
      ],
    );

    final maxH = MediaQuery.of(context).size.height * maxHeightFactor;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: body,
    );
  }
}
