import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:scandesk/core/config/app_config.dart';
import 'package:scandesk/core/demo/demo_store.dart';
import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import 'package:scandesk/core/router/routes.dart';
import 'package:scandesk/core/widgets/legend.dart';
import 'package:scandesk/core/widgets/punch_ring.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/login_form.dart';

/// Login: a teal tag header with the brand, then the form. In demo mode
/// it also offers one-tap sign-in as each role.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final onBand = theme.brightness == Brightness.light ? scheme.onPrimary : scheme.onSurface;
    final band = theme.brightness == Brightness.light ? scheme.primary : scheme.surfaceContainer;

    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final loading = state is Authenticating;
          return Column(
            children: [
              Container(
                width: double.infinity,
                color: band,
                padding: EdgeInsets.fromLTRB(
                  28,
                  MediaQuery.paddingOf(context).top + 36,
                  28,
                  32,
                ),
                child: Row(
                  children: [
                    PunchRing(
                      punchedMonths: const {1, 2, 4, 5, 7, 9, 10, 11},
                      size: 88,
                      currentMonth: DateTime.now().month,
                      // On the teal band: white stock, holes show the band.
                      disc: theme.brightness == Brightness.light
                          ? scheme.surfaceContainerLowest
                          : scheme.primary,
                      hole: band,
                      ink: theme.brightness == Brightness.light
                          ? scheme.primary
                          : scheme.onPrimary,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appTitle,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: onBand,
                              fontSize: 46,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.tagline,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: onBand.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LoginForm(
                              isLoading: loading,
                              onSubmit: (email, password) => context
                                  .read<AuthCubit>()
                                  .signIn(email: email, password: password),
                            ),
                            const SizedBox(height: 4),
                            // A Wrap, so long (or Arabic) labels drop to a
                            // second line instead of overflowing.
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => context.go(Routes.register),
                                  child: Text(l10n.noAccountRegister),
                                ),
                                TextButton(
                                  onPressed: () => context.go(Routes.forgotPassword),
                                  child: Text(l10n.forgotPassword),
                                ),
                              ],
                            ),
                            if (AppConfig.demo) ...[
                              const SizedBox(height: 20),
                              Legend(l10n.demoTryAs),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final (label, user) in [
                                    (l10n.roleEmployee, DemoStore.employee),
                                    (l10n.roleTechnician, DemoStore.technician),
                                    (l10n.roleManager, DemoStore.manager),
                                  ])
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size.fromHeight(48),
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                          ),
                                          onPressed: loading
                                              ? null
                                              : () => context.read<AuthCubit>().signIn(
                                                  email: user.email,
                                                  password: 'demo-password',
                                                ),
                                          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.demoHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
