import 'package:flutter/material.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import '../widgets/role_home_scaffold.dart';

/// Employees report problems and follow their own tickets (later sprints).
class EmployeeHomePage extends StatelessWidget {
  const EmployeeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RoleHomeScaffold(
      title: l10n.roleEmployee,
      icon: Icons.report_problem_outlined,
      description: l10n.employeeHomeHint,
    );
  }
}
