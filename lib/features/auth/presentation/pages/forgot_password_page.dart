import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import 'package:scandesk/core/router/routes.dart';
import 'package:scandesk/core/widgets/primary_button.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Asks for an email and sends a reset link through Supabase Auth.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthCubit>().sendPasswordReset(_emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
        leading: BackButton(onPressed: () => context.go(Routes.login)),
      ),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar();
            if (state is AuthError) {
              messenger.showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is PasswordResetSent) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.resetEmailSent)),
              );
              context.go(Routes.login);
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.resetPasswordHint),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email);
                            return valid ? null : l10n.invalidEmail;
                          },
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: l10n.sendResetLink,
                          isLoading: state is Authenticating,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
