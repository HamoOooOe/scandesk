import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Shown when a list has no items. Never leave a blank screen.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message ?? AppLocalizations.of(context).nothingHereYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
