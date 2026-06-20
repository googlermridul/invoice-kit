import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A safe, reusable back button for non-root screens.
///
/// - When the route stack has history ([GoRouter.canPop] returns true), it
///   pops one entry so Android system back / visible button both work.
/// - When there's nothing to pop (we're on a root screen like the dashboard),
///   it renders nothing so the title stays aligned to the start.
///
/// Usage in an [AppBar]:
/// ```dart
/// AppBar(
///   title: const Text('Invoice'),
///   leading: const AppBackButton(),
/// )
/// ```
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.color});

  /// Optional override for the tap handler. If `null`, the current route is
  /// popped.
  final VoidCallback? onPressed;

  /// Optional icon color override. Defaults to the app bar's icon color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    if (!router.canPop()) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      color: color,
      onPressed: onPressed ?? router.pop,
    );
  }
}
