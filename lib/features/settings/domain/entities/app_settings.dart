import 'package:equatable/equatable.dart';

/// User-controlled app settings (theme/locale/currency overrides).
class AppSettings extends Equatable {
  const AppSettings({
    this.themeModeName,
    this.localeCode,
    this.currency = 'USD',
    this.taxInclusive = false,
    this.sendReminders = true,
    this.markOverdueAuto = true,
    this.selectedPdfTemplate = 'classic',
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeModeName: json['themeModeName'] as String?,
    localeCode: json['localeCode'] as String?,
    currency: (json['currency'] ?? 'USD').toString(),
    taxInclusive: json['taxInclusive'] as bool? ?? false,
    sendReminders: json['sendReminders'] as bool? ?? true,
    markOverdueAuto: json['markOverdueAuto'] as bool? ?? true,
    selectedPdfTemplate: (json['selectedPdfTemplate'] ?? 'classic').toString(),
  );

  final String? themeModeName;
  final String? localeCode;
  final String currency;
  final bool taxInclusive;
  final bool sendReminders;
  final bool markOverdueAuto;
  final String selectedPdfTemplate;

  AppSettings copyWith({
    String? themeModeName,
    String? localeCode,
    String? currency,
    bool? taxInclusive,
    bool? sendReminders,
    bool? markOverdueAuto,
    String? selectedPdfTemplate,
  }) => AppSettings(
    themeModeName: themeModeName ?? this.themeModeName,
    localeCode: localeCode ?? this.localeCode,
    currency: currency ?? this.currency,
    taxInclusive: taxInclusive ?? this.taxInclusive,
    sendReminders: sendReminders ?? this.sendReminders,
    markOverdueAuto: markOverdueAuto ?? this.markOverdueAuto,
    selectedPdfTemplate: selectedPdfTemplate ?? this.selectedPdfTemplate,
  );

  Map<String, dynamic> toJson() => {
    'themeModeName': themeModeName,
    'localeCode': localeCode,
    'currency': currency,
    'taxInclusive': taxInclusive,
    'sendReminders': sendReminders,
    'markOverdueAuto': markOverdueAuto,
    'selectedPdfTemplate': selectedPdfTemplate,
  };

  @override
  List<Object?> get props => [
    themeModeName,
    localeCode,
    currency,
    taxInclusive,
    sendReminders,
    markOverdueAuto,
    selectedPdfTemplate,
  ];
}
