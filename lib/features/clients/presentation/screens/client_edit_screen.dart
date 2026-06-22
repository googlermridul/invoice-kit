import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/validators/validators.dart';
import 'package:invoice_kit/core/widgets/app_scaffold.dart';
import 'package:invoice_kit/core/widgets/section_header.dart';
import 'package:invoice_kit/features/clients/domain/entities/client.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/shared/helpers/id_generator.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class ClientEditScreen extends StatefulWidget {
  const ClientEditScreen({super.key, this.clientId});
  final String? clientId;

  @override
  State<ClientEditScreen> createState() => _ClientEditScreenState();
}

class _ClientEditScreenState extends State<ClientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _company = TextEditingController();
  final _notes = TextEditingController();

  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final cubit = context.read<ClientsCubit>();
    try {
      await cubit.load();
    } on Exception catch (_) {
      // Cubit already surfaces the error in its state; keep going so
      // the form can still be opened and the user can retry.
    }
    if (widget.clientId != null && mounted) {
      final existing = cubit.state.clients.where((c) => c.id == widget.clientId).cast<Client?>().firstOrNull;
      if (existing != null) {
        _name.text = existing.name;
        _email.text = existing.email ?? '';
        _phone.text = existing.phone ?? '';
        _address.text = existing.address ?? '';
        _company.text = existing.company ?? '';
        _notes.text = existing.notes ?? '';
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _company.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if ((value == null || value.trim().isEmpty) && _company.text.trim().isEmpty) {
      return 'Name or company is required';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final cubit = context.read<ClientsCubit>();
      final id = widget.clientId ?? IdGenerator.create('cli');
      final client = Client(
        id: id,
        name: _name.text.trim().isEmpty ? _company.text.trim() : _name.text.trim(),
        email: _nullIfEmpty(_email.text),
        phone: _nullIfEmpty(_phone.text),
        address: _nullIfEmpty(_address.text),
        company: _nullIfEmpty(_company.text),
        notes: _nullIfEmpty(_notes.text),
        createdAt: widget.clientId == null ? DateTime.now() : null,
      );
      await cubit.upsert(client);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.clientId == null ? 'Client added' : 'Client updated',
          ),
        ),
      );
      if (widget.clientId == null) {
        router.pushReplacement('/clients/$id');
      } else {
        router.pop();
      }
    } on Exception catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save client: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isNew = widget.clientId == null;
    return AppScaffold(
      title: isNew ? 'New client' : 'Edit client',
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          children: [
            const SectionHeader(
              title: 'Personal',
              uppercase: true,
              tone: SectionHeaderTone.primary,
            ),
            AppTextField(
              controller: _name,
              label: 'Full name *',
              hint: 'Jane Doe',
              validator: _validateName,
              onChanged: (_) {
                // The name rule also depends on company; trigger a
                // re-validation so the user sees the error lift as
                // they type into the company field.
                _formKey.currentState?.validate();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(
              title: 'Contact',
              uppercase: true,
              tone: SectionHeaderTone.primary,
            ),
            AppTextField(
              controller: _email,
              label: 'Email',
              hint: 'jane@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phone,
              label: 'Phone',
              hint: '+1 555 123 4567',
              keyboardType: TextInputType.phone,
              validator: Validators.phoneLenient,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(
              title: 'Business',
              uppercase: true,
              tone: SectionHeaderTone.primary,
            ),
            AppTextField(
              controller: _company,
              label: 'Company',
              hint: 'Acme Inc.',
              onChanged: (_) {
                // Cross-field: the name validator depends on company.
                _formKey.currentState?.validate();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _address,
              label: 'Address',
              hint: '123 Main St, City',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(
              title: 'Notes',
              uppercase: true,
              tone: SectionHeaderTone.primary,
            ),
            AppTextField(
              controller: _notes,
              label: 'Internal notes',
              hint: 'Anything worth remembering…',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: isNew ? 'Add client' : 'Save changes',
              icon: HugeIconsStroke.tick01,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
