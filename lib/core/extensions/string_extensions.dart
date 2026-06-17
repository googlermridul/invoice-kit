extension StringX on String {
  bool get isNullOrEmpty => isEmpty;
  bool get isNullOrBlank => trim().isEmpty;
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String get titleCase => split(' ').map((w) => w.capitalized).join(' ');

  bool get isEmail =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  bool get isPhone =>
      RegExp(r'^\+?[0-9]{7,15}$').hasMatch(replaceAll(RegExp(r'\s'), ''));

  String get maskedPhone =>
      length < 4 ? this : '${'*' * (length - 4)}${substring(length - 4)}';

  String orEmpty([String fallback = '']) => isEmpty ? fallback : this;
}

extension NullableStringX on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
