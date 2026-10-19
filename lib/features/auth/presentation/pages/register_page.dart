import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import 'package:scandesk/core/router/routes.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/register_form.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.register)),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar();
            if (state is AuthError) {
              messenger.showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is SignUpSuccess) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.registrationSuccess)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RegisterForm(
                        isLoading: state is Authenticating,
                        onSubmit: (name, email, password) =>
                            context.read<AuthCubit>().signUp(
                              fullName: name,
                              email: email,
                              password: password,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.go(Routes.login),
                        child: Text(l10n.haveAccountLogin),
                      ),
                    ],
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
