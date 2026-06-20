/// Identifiers for the built-in PDF templates. Keep in sync with constants.
class PdfTemplateIds {
  const PdfTemplateIds._();

  static const String classic = 'classic';
  static const String minimal = 'minimal';
  static const String modern = 'modern';
  static const String elegant = 'elegant';
  static const String bold = 'bold';
  static const String service = 'service';

  static const List<String> all = [
    classic,
    minimal,
    modern,
    elegant,
    bold,
    service,
  ];

  static String displayName(String id) => switch (id) {
    minimal => 'Minimal',
    modern => 'Modern',
    elegant => 'Elegant',
    bold => 'Bold Business',
    service => 'Service Freelancer',
    _ => 'Classic',
  };

  static String description(String id) => switch (id) {
    minimal => 'Crisp, lots of whitespace, single accent color.',
    modern => 'Two-tone header, bold totals.',
    elegant => 'Serif accents, refined typography.',
    bold => 'High-contrast header, strong blocks.',
    service => 'Built for hourly & service billing.',
    _ => 'A timeless invoice layout.',
  };
}
