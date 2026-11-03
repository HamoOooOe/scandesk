import 'package:flutter/material.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import 'package:scandesk/core/widgets/punch_ring.dart';

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
            PunchRing(
              punchedMonths: const {1, 2, 4, 5, 7, 9, 10, 11},
              size: 120,
              currentMonth: DateTime.now().month,
              hole: theme.colorScheme.surface,
            ),
            const SizedBox(height: 20),
            Text(l10n.appTitle, style: theme.textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(
              l10n.tagline,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
