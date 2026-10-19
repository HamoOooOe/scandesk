import 'package:flutter/material.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import 'package:scandesk/core/widgets/primary_button.dart';

/// Full name, email, password and confirm-password with validation.
/// Like LoginForm, it only collects input and calls [onSubmit].
class RegisterForm extends StatefulWidget {
  const RegisterForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  final void Function(String fullName, String email, String password) onSubmit;
  final bool isLoading;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
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
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      widget.onSubmit(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: InputDecoration(
              labelText: l10n.fullName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? l10n.nameRequired : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) =>
                (value ?? '').length >= 6 ? null : l10n.passwordTooShort,
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
            validator: (value) => value == _passwordController.text
                ? null
                : l10n.passwordsDontMatch,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: l10n.register,
            isLoading: widget.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
