import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/connectivity_banner.dart';
import '../../../assets/presentation/pages/assets_tab.dart';
import '../../../auth/domain/user_role.dart';
import '../../../dashboard/presentation/pages/dashboard_tab.dart';
import '../../../profile/presentation/pages/profile_tab.dart';
import '../../../tickets/presentation/cubit/tickets_cubit.dart';
import '../../../tickets/presentation/pages/tickets_tab.dart';

/// One tab of a role's bottom navigation bar.
class _TabSpec {
  const _TabSpec({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.body,
    this.scanFab = true,
    this.actions = const [],
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget body;
  final bool scanFab;
  final List<Widget> actions;
}

/// The signed-in app frame for every role: a Material navigation bar
/// with the tabs that role needs, and one floating scan button.
///
///  - Employee: My reports, Profile (scan to report)
///  - Technician: Queue, Assets, Profile
///  - Manager: Overview, Tickets, Assets, Profile
class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.role});

  final UserRole role;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;

  List<_TabSpec> _tabs(AppLocalizations l10n) {
    final profile = _TabSpec(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: l10n.navProfile,
      body: const ProfileTab(),
      scanFab: false,
    );
    return switch (widget.role) {
      UserRole.employee => [
        _TabSpec(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment_rounded,
          label: l10n.navMyTickets,
          body: const TicketsTab(role: UserRole.employee),
        ),
        profile,
      ],
      UserRole.technician => [
        _TabSpec(
          icon: Icons.checklist_rtl_rounded,
          selectedIcon: Icons.checklist_rounded,
          label: l10n.navQueue,
          body: const TicketsTab(role: UserRole.technician),
        ),
        _TabSpec(
          icon: Icons.devices_other_outlined,
          selectedIcon: Icons.devices_other_rounded,
          label: l10n.navAssets,
          body: const AssetsTab(role: UserRole.technician),
        ),
        profile,
      ],
      UserRole.manager => [
        _TabSpec(
          icon: Icons.space_dashboard_outlined,
          selectedIcon: Icons.space_dashboard_rounded,
          label: l10n.navOverview,
          body: const DashboardTab(),
        ),
        _TabSpec(
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment_rounded,
          label: l10n.navTickets,
          body: const TicketsTab(role: UserRole.manager),
        ),
        _TabSpec(
          icon: Icons.devices_other_outlined,
          selectedIcon: Icons.devices_other_rounded,
          label: l10n.navAssets,
          body: const AssetsTab(role: UserRole.manager),
          actions: [
            Builder(
              builder: (context) => IconButton(
                tooltip: l10n.addAsset,
                icon: const Icon(Icons.add_rounded),
                onPressed: () => context.push(Routes.assetNew),
              ),
            ),
          ],
        ),
        profile,
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = _tabs(l10n);
    final tab = tabs[_index];

    return BlocProvider(
      // A technician opens on their own queue; others on the active list.
      create: (_) => sl<TicketsCubit>()
        ..setFilter(
          widget.role == UserRole.technician ? TicketFilter.mine : TicketFilter.active,
        )
        ..start(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(tab.label),
          actions: [
            if (AppConfig.demo)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.demoBadge.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).appBarTheme.foregroundColor,
                      ),
                    ),
                  ),
                ),
              ),
            ...tab.actions,
          ],
        ),
        body: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [for (final t in tabs) t.body],
              ),
            ),
          ],
        ),
        floatingActionButton: tab.scanFab
            ? FloatingActionButton.extended(
                onPressed: () => context.push(Routes.scan),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(widget.role == UserRole.employee ? l10n.startReport : l10n.navScan),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.selectedIcon),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}
