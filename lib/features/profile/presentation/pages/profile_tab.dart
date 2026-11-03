import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_settings.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/legend.dart';
import '../../../../core/widgets/tag_card.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

/// Who you are, language and theme, and (for managers) the admin tools.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = context.watch<AuthCubit>().state;
    if (state is! Authenticated) return const SizedBox.shrink();
    final user = state.user;
    final roleLabel = switch (user.role) {
      UserRole.employee => l10n.roleEmployee,
      UserRole.technician => l10n.roleTechnician,
      UserRole.manager => l10n.roleManager,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        TagCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  user.fullName.isEmpty ? '?' : user.fullName.characters.first,
                  style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 16),
                      child: Legend(roleLabel),
                    ),
                    Text(user.fullName, style: theme.textTheme.titleLarge),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Legend(l10n.languageLabel),
        const SizedBox(height: 8),
        ValueListenableBuilder<Locale?>(
          valueListenable: AppSettings.locale,
          builder: (context, locale, _) => SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'system', label: Text(l10n.themeSystem)),
              const ButtonSegment(value: 'en', label: Text('English')),
              const ButtonSegment(value: 'ar', label: Text('العربية')),
            ],
            selected: {locale?.languageCode ?? 'system'},
            onSelectionChanged: (s) =>
                AppSettings.locale.value = s.first == 'system' ? null : Locale(s.first),
          ),
        ),
        const SizedBox(height: 20),
        Legend(l10n.appearanceLabel),
        const SizedBox(height: 8),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: AppSettings.themeMode,
          builder: (context, mode, _) => SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
              ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
            ],
            selected: {mode},
            onSelectionChanged: (s) => AppSettings.themeMode.value = s.first,
          ),
        ),
        if (user.role == UserRole.manager) ...[
          const SizedBox(height: 24),
          Legend(l10n.adminTools),
          const SizedBox(height: 8),
          TagCard(
            hole: false,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Tool(icon: Icons.group_outlined, label: l10n.manageUsers, route: Routes.manageUsers),
                const Divider(),
                _Tool(icon: Icons.apartment_outlined, label: l10n.sitesTitle, route: Routes.sites),
                const Divider(),
                _Tool(icon: Icons.qr_code_2_rounded, label: l10n.labelSheetTitle, route: Routes.labelSheet),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () => context.read<AuthCubit>().signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: Text(l10n.logout),
        ),
      ],
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(route),
    );
  }
}
