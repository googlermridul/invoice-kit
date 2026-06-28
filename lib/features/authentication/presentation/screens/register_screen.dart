import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/localization/app_localizations.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:invoice_kit/features/authentication/presentation/coordinators/post_auth_runner.dart';
import 'package:invoice_kit/features/authentication/presentation/widgets/auth_scaffold.dart';
import 'package:invoice_kit/shared/widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      title: l.authCreateAccount,
      subtitle: l.authRegister,
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (a, b) => a.message != b.message || a.status != b.status,
        listener: (context, state) async {
          if (state.message != null) {
            context.showSnackBar(state.message!);
          }
          if (state.status == AuthStatus.authenticated && state.user != null) {
            final router = GoRouter.of(context);
            await PostAuthRunner.run(
              context: context,
              router: router,
              user: state.user!,
            );
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Name',
                  hint: 'Jane Doe',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _emailController,
                  label: l.authEmail,
                  hint: 'you@example.com',
                  prefixIcon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _passwordController,
                  label: l.authPassword,
                  obscure: _obscure,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _confirmController,
                  label: 'Confirm password',
                  obscure: _obscure,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: l.authSignUp,
                  onPressed: _submit,
                  loading: state.isSubmitting,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.authAlreadyHaveAccount),
                    TextButton(
                      onPressed: () => GoRouter.of(context).pop(),
                      child: Text(l.authSignIn),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
