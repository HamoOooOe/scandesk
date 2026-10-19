import 'package:flutter/material.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import '../widgets/role_home_scaffold.dart';

/// Managers oversee assets, tickets and the team (later sprints).
class ManagerHomePage extends StatelessWidget {
  const ManagerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RoleHomeScaffold(
      title: l10n.roleManager,
      icon: Icons.admin_panel_settings_outlined,
      description: l10n.managerHomeHint,
    );
  }
}
