import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
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

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ClientsCubit>()..load();
    cubit.stream.first.then((state) {
      final existing = widget.clientId == null
          ? null
          : state.clients.where((c) => c.id == widget.clientId).cast<Client?>().firstOrNull;
      if (existing != null) {
        _name.text = existing.name;
        _email.text = existing.email ?? '';
        _phone.text = existing.phone ?? '';
        _address.text = existing.address ?? '';
        _company.text = existing.company ?? '';
        _notes.text = existing.notes ?? '';
      }
      if (mounted) setState(() => _loaded = true);
    });
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<ClientsCubit>();
    final id = widget.clientId ?? IdGenerator.create('cli');
    final client = Client(
      id: id,
      name: _name.text.trim(),
      email: _nullIfEmpty(_email.text),
      phone: _nullIfEmpty(_phone.text),
      address: _nullIfEmpty(_address.text),
      company: _nullIfEmpty(_company.text),
      notes: _nullIfEmpty(_notes.text),
      createdAt: widget.clientId == null ? DateTime.now() : null,
    );
    await cubit.upsert(client);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.clientId == null ? 'Client added' : 'Client updated')));
      context.go('/clients/$id');
    }
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isNew = widget.clientId == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'New client' : 'Edit client')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextField(
              controller: _name,
              label: 'Full name *',
              hint: 'Jane Doe',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _company,
              label: 'Company',
              hint: 'Acme Inc.',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _email,
              label: 'Email',
              hint: 'jane@example.com',
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
              controller: _notes,
              label: 'Notes',
              hint: 'Internal notes…',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: isNew ? 'Add client' : 'Save changes', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
