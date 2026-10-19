import 'package:flutter/material.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import '../widgets/role_home_scaffold.dart';

/// Technicians work on the tickets assigned to them (later sprints).
class TechnicianHomePage extends StatelessWidget {
  const TechnicianHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RoleHomeScaffold(
      title: l10n.roleTechnician,
      icon: Icons.build_outlined,
      description: l10n.technicianHomeHint,
    );
  }
}
