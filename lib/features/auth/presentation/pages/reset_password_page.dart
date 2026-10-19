import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import 'package:scandesk/core/router/routes.dart';
import 'package:scandesk/core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Opened by the link in the reset email: choose a new password.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthCubit>().updatePassword(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.setNewPassword)),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar();
            if (state is AuthError) {
              messenger.showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is PasswordUpdated) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.passwordUpdated)),
              );
              // The recovery session logged the user in; make them log in
              // again with the new password.
              context.read<AuthCubit>().signOut();
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
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.newPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => (value ?? '').length >= 6
                              ? null
                              : l10n.passwordTooShort,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l10n.confirmPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          validator: (value) =>
                              value == _passwordController.text
                              ? null
                              : l10n.passwordsDontMatch,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: l10n.savePassword,
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
