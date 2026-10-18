import 'package:flutter/material.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';

/// Shown while the AuthCubit checks for a saved session.
/// The router moves away from here automatically.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(l10n.appTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(l10n.tagline, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
