import 'package:equatable/equatable.dart';

class BusinessProfile extends Equatable {
  const BusinessProfile({
    required this.businessName,
    this.ownerName,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.taxId,
    this.logoPath,
    this.defaultCurrency = 'USD',
    this.invoicePrefix = 'INV-',
    this.quotePrefix = 'QUO-',
    this.nextInvoiceNumber = 1,
    this.nextQuoteNumber = 1,
    this.defaultPaymentTerms = 'Payment due within 14 days.',
    this.defaultNotes,
    this.bankDetails,
    this.paymentInstructions,
    this.selectedPdfTemplate = 'classic',
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) =>
      BusinessProfile(
        businessName: (json['businessName'] ?? 'My Business').toString(),
        ownerName: json['ownerName'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        website: json['website'] as String?,
        taxId: json['taxId'] as String?,
        logoPath: json['logoPath'] as String?,
        defaultCurrency: (json['defaultCurrency'] ?? 'USD').toString(),
        invoicePrefix: (json['invoicePrefix'] ?? 'INV-').toString(),
        quotePrefix: (json['quotePrefix'] ?? 'QUO-').toString(),
        nextInvoiceNumber: (json['nextInvoiceNumber'] as num?)?.toInt() ?? 1,
        nextQuoteNumber: (json['nextQuoteNumber'] as num?)?.toInt() ?? 1,
        defaultPaymentTerms:
            (json['defaultPaymentTerms'] ?? 'Payment due within 14 days.')
                .toString(),
        defaultNotes: json['defaultNotes'] as String?,
        bankDetails: json['bankDetails'] as String?,
        paymentInstructions: json['paymentInstructions'] as String?,
        selectedPdfTemplate: (json['selectedPdfTemplate'] ?? 'classic')
            .toString(),
      );

  final String businessName;
  final String? ownerName;
  final String? email;
  final String? phone;
  final String? address;
  final String? website;
  final String? taxId;
  final String? logoPath;
  final String defaultCurrency;
  final String invoicePrefix;
  final String quotePrefix;
  final int nextInvoiceNumber;
  final int nextQuoteNumber;
  final String defaultPaymentTerms;
  final String? defaultNotes;
  final String? bankDetails;
  final String? paymentInstructions;
  final String selectedPdfTemplate;

  BusinessProfile copyWith({
    String? businessName,
    String? ownerName,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? taxId,
    String? logoPath,
    String? defaultCurrency,
    String? invoicePrefix,
    String? quotePrefix,
    int? nextInvoiceNumber,
    int? nextQuoteNumber,
    String? defaultPaymentTerms,
    String? defaultNotes,
    String? bankDetails,
    String? paymentInstructions,
    String? selectedPdfTemplate,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      taxId: taxId ?? this.taxId,
      logoPath: logoPath ?? this.logoPath,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      quotePrefix: quotePrefix ?? this.quotePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      nextQuoteNumber: nextQuoteNumber ?? this.nextQuoteNumber,
      defaultPaymentTerms: defaultPaymentTerms ?? this.defaultPaymentTerms,
      defaultNotes: defaultNotes ?? this.defaultNotes,
      bankDetails: bankDetails ?? this.bankDetails,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      selectedPdfTemplate: selectedPdfTemplate ?? this.selectedPdfTemplate,
    );
  }

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'ownerName': ownerName,
    'email': email,
    'phone': phone,
    'address': address,
    'website': website,
    'taxId': taxId,
    'logoPath': logoPath,
    'defaultCurrency': defaultCurrency,
    'invoicePrefix': invoicePrefix,
    'quotePrefix': quotePrefix,
    'nextInvoiceNumber': nextInvoiceNumber,
    'nextQuoteNumber': nextQuoteNumber,
    'defaultPaymentTerms': defaultPaymentTerms,
    'defaultNotes': defaultNotes,
    'bankDetails': bankDetails,
    'paymentInstructions': paymentInstructions,
    'selectedPdfTemplate': selectedPdfTemplate,
  };

  @override
  List<Object?> get props => [
    businessName,
    ownerName,
    email,
    phone,
    address,
    website,
    taxId,
    logoPath,
    defaultCurrency,
    invoicePrefix,
    quotePrefix,
    nextInvoiceNumber,
    nextQuoteNumber,
    defaultPaymentTerms,
    defaultNotes,
    bankDetails,
    paymentInstructions,
    selectedPdfTemplate,
  ];
}
