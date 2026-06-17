import 'package:flutter/material.dart';

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

  Future<T?> push<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));

  Future<T?> pushNamed<T>(String route, {Object? arguments}) =>
      Navigator.of(this).pushNamed<T>(route, arguments: arguments);

  void pop<T>([T? result]) => Navigator.of(this).pop<T>(result);

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
}
