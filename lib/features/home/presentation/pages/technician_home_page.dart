import 'package:flutter/material.dart';

import '../../../auth/domain/user_role.dart';
import '../widgets/role_shell.dart';

/// Technicians work their queue and scan devices.
class TechnicianHomePage extends StatelessWidget {
  const TechnicianHomePage({super.key});

  @override
  Widget build(BuildContext context) => const RoleShell(role: UserRole.technician);
}
