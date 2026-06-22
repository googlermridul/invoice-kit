import 'package:invoice_kit/core/extensions/string_extensions.dart';

/// Lightweight field-level validators used by forms/blocs.
class Validators {
  const Validators._();

  static String? email(String? value) {
    if (value.isNullOrEmpty) return 'Email is required';
    if (!value!.isEmail) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value.isNullOrEmpty) return 'Password is required';
    if (value!.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp('[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp('[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    if (!value.contains(RegExp('[0-9]'))) {
      return 'Password must contain a digit';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value.isNullOrEmpty) return 'Confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value) {
    if (value.isNullOrEmpty) return 'Phone number is required';
    if (!value!.isPhone) return 'Enter a valid phone number';
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value.isNullOrEmpty) return '$fieldName is required';
    return null;
  }

  static String? minLength(
    String? value,
    int length, {
    String fieldName = 'This field',
  }) {
    if (value.isNullOrEmpty) return '$fieldName is required';
    if (value!.length < length) {
      return '$fieldName must be at least $length characters';
    }
    return null;
  }

  static String? compose(String? value, List<String? Function(String?)> rules) {
    for (final rule in rules) {
      final error = rule(value);
      if (error != null) return error;
    }
    return null;
  }

  /// Phone validator that allows empty input. Returns null when the
  /// field is empty or whitespace; otherwise runs the same format
  /// check as [Validators.phone]. Use for optional phone fields like
  /// on the client form.
  static String? phoneLenient(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!value.isPhone) return 'Enter a valid phone number';
    return null;
  }

  /// Validates that a numeric field parses to a non-negative number
  /// (zero or greater). Use for tax rate, discount, and unit price.
  static String? nonNegativeNumber(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value.isNullOrEmpty) return '$fieldName is required';
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return '$fieldName cannot be negative';
    return null;
  }

  /// Validates that a numeric field parses to a strictly positive
  /// number (> 0). Use for quantity.
  static String? positiveNumber(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value.isNullOrEmpty) return '$fieldName is required';
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return '$fieldName must be greater than 0';
    return null;
  }
}
