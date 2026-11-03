import 'package:flutter/material.dart';

import '../../../auth/domain/user_role.dart';
import '../widgets/role_shell.dart';

/// Employees report problems and follow their tickets.
class EmployeeHomePage extends StatelessWidget {
  const EmployeeHomePage({super.key});

  @override
  Widget build(BuildContext context) => const RoleShell(role: UserRole.employee);
}
