import 'package:flutter/material.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/widgets/app_back_button.dart';

/// Standard scaffold used by most non-root screens.
///
/// Wraps the body in a [SafeArea] and applies consistent page padding,
/// optional pull-to-refresh, and a GoRouter-aware back button.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.xxl,
    ),
    this.bottom,
    this.bottomBar,
    this.refreshable = false,
    this.onRefresh,
    this.backgroundColor,
    this.centerTitle = false,
    this.largeTitle = false,
    this.resizeToAvoidBottomInset = true,
  });

  /// Variant with a fixed bottom CTA (e.g. save button).
  const AppScaffold.withBottomBar({
    required this.body,
    required Widget this.bottomBar,
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    this.bottom,
    this.refreshable = false,
    this.onRefresh,
    this.backgroundColor,
    this.centerTitle = false,
    this.largeTitle = false,
    this.resizeToAvoidBottomInset = true,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? body;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final EdgeInsetsGeometry padding;
  final PreferredSizeWidget? bottom;
  final bool refreshable;
  final Future<void> Function()? onRefresh;
  final Color? backgroundColor;
  final bool centerTitle;
  final bool largeTitle;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    var content = body;
    if (body != null && padding != EdgeInsets.zero) {
      content = Padding(padding: padding, child: body);
    }
    if (refreshable && content != null && onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: scheme.primary,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? scheme.surface,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: (title == null && leading == null && actions == null)
          ? null
          : AppBar(
              title: title == null
                  ? null
                  : Text(
                      title!,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
              centerTitle: centerTitle,
              leading: leading ?? const AppBackButton(),
              actions: actions,
              bottom: bottom,
            ),
      body: SafeArea(
        top: bottomBar == null,
        bottom: bottomBar == null,
        child: content ?? const SizedBox.shrink(),
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: bottomBar,
              ),
            ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
