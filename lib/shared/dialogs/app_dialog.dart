import 'package:flutter/material.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';

class AppDialog {
  const AppDialog._();

  /// Show a confirmation dialog. Returns:
  ///   - `true` if the user tapped the confirm button,
  ///   - `false` if they tapped cancel,
  ///   - `null` if they dismissed the dialog (tap outside, back button).
  ///
  /// Callers should treat `!= true` as "do not proceed with the
  /// destructive action" — `null` is *not* consent.
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: context.colors.error)
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result;
  }

  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String okText = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(okText),
          ),
        ],
      ),
    );
  }
}
