import 'package:flutter/material.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  MediaQueryData get media => MediaQuery.of(this);
  Size get screen => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  double get statusBarHeight => MediaQuery.paddingOf(this).top;
  double get bottomBarHeight => MediaQuery.paddingOf(this).bottom;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  void hideKeyboard() => FocusScope.of(this).unfocus();

  /// Responsive width (out of 375 baseline).
  double rw(double value) => (value / 375) * screenWidth;

  /// Responsive height (out of 812 baseline).
  double rh(double value) => (value / 812) * screenHeight;

  /// Responsive font size.
  double rsp(double value) {
    final scale = screenWidth / 375;
    final result = value * scale;
    final lower = value * 0.85;
    final upper = value * 1.25;
    return result.clamp(lower, upper);
  }

  /// Add a Material gap.
  SizedBox gap(double value) => SizedBox(width: value, height: value);

  /// Horizontal-only gap.
  SizedBox hgap(double value) => SizedBox(width: value);

  /// Vertical-only gap.
  SizedBox vgap(double value) => SizedBox(height: value);

  void showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Themed snackbar variants.
  void showSuccessSnack(String message) =>
      showSnackBar(message, color: tokens.surfaceInverse);
  void showErrorSnack(String message) =>
      showSnackBar(message, color: colors.error);
}
