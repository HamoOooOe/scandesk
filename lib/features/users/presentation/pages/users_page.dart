import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:scandesk/core/di/injection.dart';
import 'package:scandesk/core/l10n/generated/app_localizations.dart';
import 'package:scandesk/core/router/routes.dart';
import 'package:scandesk/core/widgets/empty_view.dart';
import 'package:scandesk/core/widgets/error_view.dart';
import 'package:scandesk/core/widgets/loading_view.dart';

import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/users_cubit.dart';
import '../cubit/users_state.dart';

/// Manager-only screen: list users and change their role.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UsersCubit>()..load(),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  String _roleLabel(AppLocalizations l10n, UserRole role) => switch (role) {
    UserRole.employee => l10n.roleEmployee,
    UserRole.technician => l10n.roleTechnician,
    UserRole.manager => l10n.roleManager,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthCubit>().state;
    final myId = authState is Authenticated ? authState.user.id : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageUsers),
        leading: BackButton(onPressed: () => context.go(Routes.managerHome)),
      ),
      body: BlocConsumer<UsersCubit, UsersState>(
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            current.status == UsersStatus.loaded,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!))),
        builder: (context, state) {
          switch (state.status) {
            case UsersStatus.loading:
              return const LoadingView();
            case UsersStatus.error:
              return ErrorView(
                message: state.errorMessage,
                onRetry: () => context.read<UsersCubit>().load(),
              );
            case UsersStatus.loaded:
              if (state.users.isEmpty) return const EmptyView();
              return ListView.separated(
                itemCount: state.users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  // A manager can't change their own role: they could
                  // lock themselves out.
                  final isMe = user.id == myId;
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user.fullName.isEmpty ? '-' : user.fullName),
                    subtitle: Text(_roleLabel(l10n, user.role)),
                    trailing: isMe
                        ? null
                        : PopupMenuButton<UserRole>(
                            tooltip: l10n.changeRole,
                            icon: const Icon(Icons.swap_horiz),
                            initialValue: user.role,
                            onSelected: (role) => context
                                .read<UsersCubit>()
                                .changeRole(user.id, role),
                            itemBuilder: (_) => [
                              for (final role in UserRole.values)
                                PopupMenuItem(
                                  value: role,
                                  child: Text(_roleLabel(l10n, role)),
                                ),
                            ],
                          ),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
