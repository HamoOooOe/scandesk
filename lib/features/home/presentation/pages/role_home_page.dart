import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

/// Temporary placeholder shared by all roles (replaced in the next PR by
/// three real home screens).
class RoleHomePage extends StatelessWidget {
  const RoleHomePage({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AuthCubit>().state;
    final name = state is Authenticated ? state.user.fullName : '';
    final roleLabel = switch (role) {
      UserRole.employee => l10n.roleEmployee,
      UserRole.technician => l10n.roleTechnician,
      UserRole.manager => l10n.roleManager,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(roleLabel),
        actions: [
          IconButton(
            tooltip: l10n.logout,
            onPressed: () => context.read<AuthCubit>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(child: Text(l10n.welcomeUser(name))),
    );
  }
}
