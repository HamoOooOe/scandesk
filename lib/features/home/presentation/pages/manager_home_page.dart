import 'package:flutter/material.dart';

import '../../../auth/domain/user_role.dart';
import '../widgets/role_shell.dart';

/// Managers oversee tickets, assets and the team.
class ManagerHomePage extends StatelessWidget {
  const ManagerHomePage({super.key});

  @override
  Widget build(BuildContext context) => const RoleShell(role: UserRole.manager);
}
