import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoice_kit/core/theme/app_colors.dart';
import 'package:invoice_kit/core/theme/app_nav_tokens.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/core/theme/app_typography.dart';

/// Centralised ThemeData factory for InvoiceKit.
abstract class AppTheme {
  static ThemeData get light => _build(brightness: Brightness.light);
  static ThemeData get dark => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isLight = brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light() : AppTokens.dark();

    final primary = isLight ? AppColors.primary : AppColors.primaryAccent;
    final onPrimary = AppColors.white;
    final background = isLight
        ? AppColors.lightBackground
        : AppColors.darkBackground;
    final surface = isLight ? AppColors.lightSurface : AppColors.darkSurface;
    final surfaceContainerLowest = isLight
        ? AppColors.lightBackground
        : AppColors.darkBackground;
    final surfaceContainerLow = isLight
        ? AppColors.lightSurface
        : AppColors.darkSurface;
    final surfaceContainer = isLight
        ? AppColors.lightSurfaceAlt
        : AppColors.darkSurfaceAlt;
    final surfaceContainerHigh = isLight
        ? AppColors.lightSurfaceAlt
        : AppColors.darkSurfaceAlt;
    final surfaceContainerHighest = isLight
        ? AppColors.lightSurfaceAlt
        : AppColors.darkSurfaceAlt;
    final onSurface = isLight ? AppColors.lightText : AppColors.darkText;
    final onSurfaceMuted = isLight
        ? AppColors.lightTextMuted
        : AppColors.darkTextMuted;
    final outline = isLight ? AppColors.lightBorder : AppColors.darkBorder;
    final outlineVariant = isLight
        ? AppColors.lightBorder
        : AppColors.darkBorder;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: tokens.brandSubtle,
      onPrimaryContainer: isLight ? AppColors.primaryDark : AppColors.white,
      secondary: AppColors.tertiary,
      onSecondary: AppColors.white,
      secondaryContainer: tokens.tertiarySubtle,
      onSecondaryContainer: isLight ? AppColors.primaryDark : AppColors.white,
      tertiary: AppColors.premium,
      onTertiary: AppColors.white,
      tertiaryContainer: tokens.brandSubtle,
      onTertiaryContainer: isLight ? AppColors.primaryDark : AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: tokens.errorSubtle,
      onErrorContainer: isLight ? AppColors.error : AppColors.errorLight,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      onSurfaceVariant: onSurfaceMuted,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: isLight ? const Color(0xFF0F172A) : const Color(0xFF000000),
      scrim: isLight ? const Color(0x66000000) : const Color(0x99000000),
      inverseSurface: isLight ? AppColors.lightText : AppColors.darkSurfaceAlt,
      onInverseSurface: isLight
          ? AppColors.lightBackground
          : AppColors.darkText,
      inversePrimary: AppColors.primaryAccent,
      surfaceTint: primary,
    );

    final baseText = AppTypography.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: outline,
      fontFamily: AppTypography.bodyFont,
      textTheme: baseText,
      primaryTextTheme: baseText,
      splashFactory: InkSparkle.splashFactory,
      hoverColor: tokens.brandSubtle,
      focusColor: tokens.brandSubtle,
      highlightColor: tokens.brandSubtle,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        toolbarHeight: AppSize.appBarHeight,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: AppColors.transparent,
                systemNavigationBarColor: background,
                systemNavigationBarIconBrightness: Brightness.dark,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: AppColors.transparent,
                systemNavigationBarColor: background,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: onSurface, size: AppSize.iconLg),
        actionsIconTheme: IconThemeData(color: onSurface, size: AppSize.iconLg),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: isLight
            ? const Color(0x140B1220)
            : const Color(0x66000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.lightSurfaceAlt.withValues(alpha: 0.6)
            : AppColors.darkSurfaceAlt.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: baseText.bodyMedium?.copyWith(color: onSurfaceMuted),
        labelStyle: baseText.bodyMedium?.copyWith(color: onSurfaceMuted),
        floatingLabelStyle: baseText.bodyMedium?.copyWith(color: primary),
        helperStyle: baseText.bodySmall?.copyWith(color: onSurfaceMuted),
        errorStyle: baseText.bodySmall?.copyWith(color: AppColors.error),
        prefixIconColor: onSurfaceMuted,
        suffixIconColor: onSurfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: outline.withValues(alpha: 0.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: outline,
          disabledForegroundColor: onSurfaceMuted,
          minimumSize: const Size.fromHeight(AppSize.buttonHeight),
          elevation: 0,
          shadowColor: AppColors.transparent,
          surfaceTintColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(AppSize.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(AppSize.buttonHeight),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurface,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(AppSpacing.sm),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        focusColor: tokens.brandSubtle,
        hoverColor: tokens.brandSubtle,
        extendedTextStyle: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: onPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.surfaceInverse,
        contentTextStyle: baseText.bodyMedium?.copyWith(
          color: tokens.onSurfaceInverse,
        ),
        actionTextColor: AppColors.primaryAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceMuted,
        labelStyle: baseText.labelMedium?.copyWith(color: onSurface),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurfaceMuted,
        textColor: onSurface,
        titleTextStyle: baseText.bodyLarge?.copyWith(color: onSurface),
        subtitleTextStyle: baseText.bodySmall?.copyWith(color: onSurfaceMuted),
        leadingAndTrailingTextStyle: baseText.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        surfaceTintColor: AppColors.transparent,
        indicatorColor: tokens.brandSubtle,
        labelTextStyle: WidgetStatePropertyAll(
          baseText.labelSmall?.copyWith(color: onSurface),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: onSurface, size: AppSize.iconLg),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: onSurfaceMuted,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: outline,
        labelStyle: baseText.labelLarge,
        unselectedLabelStyle: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: baseText.titleLarge?.copyWith(color: onSurface),
        contentTextStyle: baseText.bodyMedium?.copyWith(color: onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        modalBackgroundColor: surface,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return isLight ? AppColors.lightSurface : AppColors.darkSurface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return outline;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return AppColors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: BorderSide(color: outline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return onSurfaceMuted;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: outline),
        ),
        textStyle: baseText.bodyMedium?.copyWith(color: onSurface),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.surfaceInverse,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: baseText.bodySmall?.copyWith(
          color: tokens.onSurfaceInverse,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: tokens.surfaceMuted,
        circularTrackColor: tokens.surfaceMuted,
        linearMinHeight: 4,
      ),
      extensions: [
        tokens,
        if (isLight) AppNavTokens.light() else AppNavTokens.dark(),
      ],
    );
  }
}

// class AppTheme {
//   AppTheme._();

//   static ThemeData light() {
//     final base = ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.light,
//       colorScheme: const ColorScheme.light(
//         primary: AppColors.primary,
//         onPrimary: Colors.white,
//         secondary: AppColors.tertiary,
//         onSecondary: Colors.black,
//         surface: AppColors.lightSurface,
//         onSurface: AppColors.lightText,
//         surfaceContainerHighest: AppColors.lightBackground,
//         outline: AppColors.lightBorder,
//         error: AppColors.error,
//       ),
//       scaffoldBackgroundColor: AppColors.lightBackground,
//       textTheme: const TextTheme(
//         displayLarge: AppTypography.displayLarge,
//         headlineLarge: AppTypography.headlineLarge,
//         headlineMedium: AppTypography.headlineMedium,
//         titleLarge: AppTypography.titleLarge,
//         titleMedium: AppTypography.titleMedium,
//         bodyLarge: AppTypography.bodyLarge,
//         bodyMedium: AppTypography.bodyMedium,
//         bodySmall: AppTypography.bodySmall,
//         labelLarge: AppTypography.labelLarge,
//         labelMedium: AppTypography.labelMedium,
//       ),
//     );
//     return _applySharedDecorations(base);
//   }

//   static ThemeData dark() {
//     final base = ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.dark,
//       colorScheme: const ColorScheme.dark(
//         primary: AppColors.primary,
//         onPrimary: Colors.white,
//         secondary: AppColors.tertiary,
//         onSecondary: Colors.black,
//         surface: AppColors.darkSurface,
//         onSurface: AppColors.darkText,
//         surfaceContainerHighest: AppColors.darkBackground,
//         outline: AppColors.darkBorder,
//         error: AppColors.error,
//       ),
//       scaffoldBackgroundColor: AppColors.darkBackground,
//       textTheme: const TextTheme(
//         displayLarge: AppTypography.displayLarge,
//         headlineLarge: AppTypography.headlineLarge,
//         headlineMedium: AppTypography.headlineMedium,
//         titleLarge: AppTypography.titleLarge,
//         titleMedium: AppTypography.titleMedium,
//         bodyLarge: AppTypography.bodyLarge,
//         bodyMedium: AppTypography.bodyMedium,
//         bodySmall: AppTypography.bodySmall,
//         labelLarge: AppTypography.labelLarge,
//         labelMedium: AppTypography.labelMedium,
//       ),
//     );
//     return _applySharedDecorations(base);
//   }

//   static ThemeData _applySharedDecorations(ThemeData base) {
//     return base.copyWith(
//       appBarTheme: AppBarTheme(
//         backgroundColor: base.scaffoldBackgroundColor,
//         foregroundColor: base.colorScheme.onSurface,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         centerTitle: false,
//         titleTextStyle: AppTypography.titleLarge.copyWith(
//           color: base.colorScheme.onSurface,
//         ),
//       ),
//       cardTheme: CardThemeData(
//         color: base.colorScheme.surface,
//         elevation: 0,
//         margin: EdgeInsets.zero,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//           side: BorderSide(color: base.colorScheme.outline, width: 1),
//         ),
//       ),
//       filledButtonTheme: FilledButtonThemeData(
//         style: FilledButton.styleFrom(
//           minimumSize: const Size(0, 48),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           textStyle: AppTypography.labelLarge,
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           minimumSize: const Size(0, 48),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       ),
//       chipTheme: ChipThemeData(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(999),
//         ),
//         side: BorderSide.none,
//         backgroundColor: base.colorScheme.surfaceContainerHighest,
//         labelStyle: AppTypography.labelMedium,
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: base.colorScheme.surfaceContainerHighest,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide.none,
//         ),
//       ),
//       dividerTheme: DividerThemeData(
//         color: base.colorScheme.outline,
//         thickness: 1,
//         space: 1,
//       ),
//     );
//   }
// }
