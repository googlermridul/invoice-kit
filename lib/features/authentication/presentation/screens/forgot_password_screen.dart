import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_boilerplate/core/localization/app_localizations.dart';
import 'package:flutter_boilerplate/core/theme/app_spacing.dart';
import 'package:flutter_boilerplate/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:flutter_boilerplate/features/authentication/presentation/widgets/auth_scaffold.dart';
import 'package:flutter_boilerplate/shared/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthForgotPasswordRequested(email: _emailController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      title: l.authForgotPassword,
      subtitle: l.authEmail,
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (a, b) => a.message != b.message,
        listener: (context, state) {
          if (state.message != null) {
            context.showSnackBar(state.message!);
            if (!state.isSubmitting && (state.message?.contains('sent') ?? false)) {
              context.go('/login');
            }
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _emailController,
                  label: l.authEmail,
                  hint: 'you@example.com',
                  prefixIcon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: l.commonSubmit,
                  onPressed: _submit,
                  loading: state.isSubmitting,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(onPressed: () => context.go('/login'), child: Text(l.commonBack)),
              ],
            ),
          );
        },
      ),
    );
  }
}
