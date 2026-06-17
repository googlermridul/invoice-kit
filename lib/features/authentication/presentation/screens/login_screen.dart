import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_boilerplate/core/localization/app_localizations.dart';
import 'package:flutter_boilerplate/core/router/route_paths.dart';
import 'package:flutter_boilerplate/core/theme/app_spacing.dart';
import 'package:flutter_boilerplate/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:flutter_boilerplate/features/authentication/presentation/widgets/auth_scaffold.dart';
import 'package:flutter_boilerplate/shared/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // if (_formKey.currentState!.validate()) {
    // context.read<AuthBloc>().add(
    //   AuthLoginRequested(email: _emailController.text.trim(), password: _passwordController.text),
    // );
    context.go(RoutePaths.home);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      title: l.authWelcomeBack,
      subtitle: l.authSignIn,
      child: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (a, b) => a.message != b.message || a.status != b.status,
        listener: (context, state) {
          if (state.message != null) {
            context.showSnackBar(state.message!);
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
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _passwordController,
                  label: l.authPassword,
                  obscure: _obscure,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: Text(l.authForgotPassword),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(label: l.authLogin, onPressed: _submit, loading: state.isSubmitting),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.authDontHaveAccount),
                    TextButton(onPressed: () => context.go('/register'), child: Text(l.authSignUp)),
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
