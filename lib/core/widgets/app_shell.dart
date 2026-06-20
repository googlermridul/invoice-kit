import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_nav_tokens.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';

/// One entry in the bottom navigation bar.
class AppShellDestination {
  const AppShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Five bottom-nav destinations used across all main tabs.
///
/// Icons are Hugeicons — unselected uses the stroke variant, selected
/// uses the solid variant, so the active tab is visually unmistakable
/// even at small sizes.
class AppShellDestinations {
  const AppShellDestinations._();

  static const home = AppShellDestination(
    label: 'Home',
    icon: HugeIconsStroke.home01,
    selectedIcon: HugeIconsSolid.home01,
  );

  static const invoices = AppShellDestination(
    label: 'Invoices',
    icon: HugeIconsStroke.invoice01,
    selectedIcon: HugeIconsSolid.invoice01,
  );

  static const clients = AppShellDestination(
    label: 'Clients',
    icon: HugeIconsStroke.userGroup,
    selectedIcon: HugeIconsSolid.userGroup,
  );

  static const reports = AppShellDestination(
    label: 'Reports',
    icon: HugeIconsStroke.chart,
    selectedIcon: HugeIconsSolid.chart,
  );

  static const settings = AppShellDestination(
    label: 'Settings',
    icon: HugeIconsStroke.settings01,
    selectedIcon: HugeIconsSolid.settings01,
  );

  static const List<AppShellDestination> all = [
    home,
    invoices,
    clients,
    reports,
    settings,
  ];
}

/// The persistent iOS-inspired shell that wraps the five main tabs.
///
/// The bar:
///   * reads its colors from [AppNavTokens] (theme-driven, light + dark)
///   * uses Hugeicons stroke/solid variants for clear selected/unselected
///   * shows an active pill behind the selected icon (premium feel)
///   * synchronises selection with [StatefulNavigationShell.currentIndex]
///   * re-tapping the active tab pops to the tab root if the stack
///     has sub-routes, otherwise leaves the user where they are
class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    // Re-tap on the active tab → pop to root of that tab.
    if (index == navigationShell.currentIndex) {
      navigationShell.goBranch(
        index,
        initialLocation: true,
      );
      return;
    }
    navigationShell.goBranch(
      index,
      // Switching tabs should keep each tab's own history alive.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.navTokens;
    final destinations = AppShellDestinations.all;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        destinations: destinations,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        background: nav.background,
        border: nav.border,
        activeColor: nav.activeColor,
        inactiveColor: nav.inactiveColor,
        activePill: nav.activePill,
        labelColor: nav.label,
        shadow: nav.shadow,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.destinations,
    required this.currentIndex,
    required this.onTap,
    required this.background,
    required this.border,
    required this.activeColor,
    required this.inactiveColor,
    required this.activePill,
    required this.labelColor,
    required this.shadow,
  });

  final List<AppShellDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color background;
  final Color border;
  final Color activeColor;
  final Color inactiveColor;
  final Color activePill;
  final Color labelColor;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(
            top: BorderSide(color: border, width: 0.6),
          ),
          boxShadow: shadow,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavItem(
                  destination: destinations[i],
                  selected: i == currentIndex,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  activePill: activePill,
                  labelColor: labelColor,
                  textTheme: textTheme,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.activePill,
    required this.labelColor,
    required this.textTheme,
    required this.onTap,
  });

  final AppShellDestination destination;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final Color activePill;
  final Color labelColor;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconData = selected ? destination.selectedIcon : destination.icon;
    final fg = selected ? activeColor : inactiveColor;

    return InkResponse(
      onTap: onTap,
      radius: 48,
      highlightShape: BoxShape.circle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: selected ? activePill : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(
                iconData,
                size: 22,
                color: fg,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
                color: selected ? labelColor : inactiveColor,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
              child: Text(destination.label),
            ),
          ],
        ),
      ),
    );
  }
}
