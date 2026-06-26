import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/widgets/widgets.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';
import 'package:invoice_kit/features/business_profile/presentation/bloc/business_profile_cubit.dart';
import 'package:invoice_kit/features/invoices/domain/entities/pdf_template.dart';
import 'package:invoice_kit/shared/widgets/app_text_field.dart';
import 'package:invoice_kit/shared/widgets/buttons.dart';
import 'package:invoice_kit/shared/widgets/logo_picker.dart';
import 'package:invoice_kit/shared/widgets/searchable_picker_sheet.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _ownerName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _website = TextEditingController();
  final _taxId = TextEditingController();
  final _defaultTerms = TextEditingController();
  final _bankDetails = TextEditingController();
  final _paymentInstructions = TextEditingController();
  final _invoicePrefix = TextEditingController();
  final _quotePrefix = TextEditingController();

  String _currency = 'USD';
  String _pdfTemplate = PdfTemplateIds.classic;
  String? _logoPath;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<BusinessProfileCubit>()..load();
    cubit.stream.first.then((s) {
      final p = s.profile;
      if (p != null) _hydrate(p);
      if (mounted) setState(() => _loaded = true);
    });
  }

  void _hydrate(BusinessProfile p) {
    _businessName.text = p.businessName;
    _ownerName.text = p.ownerName ?? '';
    _email.text = p.email ?? '';
    _phone.text = p.phone ?? '';
    _address.text = p.address ?? '';
    _website.text = p.website ?? '';
    _taxId.text = p.taxId ?? '';
    _defaultTerms.text = p.defaultPaymentTerms;
    _bankDetails.text = p.bankDetails ?? '';
    _paymentInstructions.text = p.paymentInstructions ?? '';
    _invoicePrefix.text = p.invoicePrefix;
    _quotePrefix.text = p.quotePrefix;
    _currency = p.defaultCurrency;
    _pdfTemplate = p.selectedPdfTemplate;
    _logoPath = p.logoPath;
  }

  @override
  void dispose() {
    _businessName.dispose();
    _ownerName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _website.dispose();
    _taxId.dispose();
    _defaultTerms.dispose();
    _bankDetails.dispose();
    _paymentInstructions.dispose();
    _invoicePrefix.dispose();
    _quotePrefix.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<BusinessProfileCubit>();
    final existing = cubit.state.profile;
    final updated = BusinessProfile(
      businessName: _businessName.text.trim(),
      ownerName: _nullIfEmpty(_ownerName.text),
      email: _nullIfEmpty(_email.text),
      phone: _nullIfEmpty(_phone.text),
      address: _nullIfEmpty(_address.text),
      website: _nullIfEmpty(_website.text),
      taxId: _nullIfEmpty(_taxId.text),
      logoPath: _logoPath,
      defaultCurrency: _currency,
      invoicePrefix: _invoicePrefix.text.trim().isEmpty
          ? InvoiceConstants.defaultInvoicePrefix
          : _invoicePrefix.text.trim(),
      quotePrefix: _quotePrefix.text.trim().isEmpty
          ? InvoiceConstants.defaultQuotePrefix
          : _quotePrefix.text.trim(),
      nextInvoiceNumber: existing?.nextInvoiceNumber ?? 1,
      nextQuoteNumber: existing?.nextQuoteNumber ?? 1,
      defaultPaymentTerms: _defaultTerms.text.trim().isEmpty
          ? 'Payment due within 3 days.'
          : _defaultTerms.text.trim(),
      bankDetails: _nullIfEmpty(_bankDetails.text),
      paymentInstructions: _nullIfEmpty(_paymentInstructions.text),
      selectedPdfTemplate: _pdfTemplate,
    );
    await cubit.save(updated);
    await sl<BusinessProfileRepository>().save(updated);
    if (mounted) context.showSnackBar('Profile saved');
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AppScaffold(
      title: 'Business profile',
      refreshable: true,
      onRefresh: () => context.read<BusinessProfileCubit>().load(),
      actions: [
        IconButton(
          icon: const Icon(HugeIconsStroke.folder01, size: 18),
          tooltip: 'Save',
          onPressed: _save,
        ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SectionHeader(
              title: 'Business',
              uppercase: true,
              tone: SectionHeaderTone.primary,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  LogoPicker(
                    value: _logoPath,
                    onChanged: (p) => setState(() => _logoPath = p),
                  ),
                  const Divider(height: AppSpacing.lg),
                  AppTextField(
                    controller: _businessName,
                    label: 'Business name',
                    hint: 'Acme Studio',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _ownerName,
                    label: 'Owner / contact name',
                    hint: 'Jane Doe',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _email,
                    label: 'Email',
                    hint: 'billing@acme.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _phone,
                    label: 'Phone',
                    hint: '+1 555 123 4567',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _address,
                    label: 'Address',
                    hint: '123 Main St, City',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _website,
                    label: 'Website',
                    hint: 'https://acme.com',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(
              title: 'Invoicing',
              uppercase: true,
              tone: SectionHeaderTone.primary,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  SearchableCurrencyPickerRow(
                    selected: _currency,
                    options: CurrencyCodes.common,
                    onSelected: (c) => setState(() => _currency = c),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _invoicePrefix,
                    label: 'Invoice number prefix',
                    hint: 'INV-',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _quotePrefix,
                    label: 'Quote number prefix',
                    hint: 'QUO-',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _taxId,
                    label: 'Tax ID / VAT',
                    hint: '123456789',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _defaultTerms,
                    label: 'Default payment terms',
                    hint: 'Payment due within 3 days.',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(
              title: 'Payment details',
              uppercase: true,
              tone: SectionHeaderTone.primary,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    controller: _bankDetails,
                    label: 'Bank details',
                    hint: 'Bank name · Account · Routing',
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _paymentInstructions,
                    label: 'Payment instructions',
                    hint: 'Pay via bank transfer to the account above.',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Save profile',
              icon: Icons.save_outlined,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
