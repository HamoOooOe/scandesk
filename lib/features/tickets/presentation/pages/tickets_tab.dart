import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/tickets_cubit.dart';
import '../widgets/ticket_row.dart';

/// The ticket list for every role, with the filters that role needs:
/// employees see their reports, technicians their queue, managers all.
class TicketsTab extends StatelessWidget {
  const TicketsTab({super.key, required this.role});

  final UserRole role;

  List<TicketFilter> get _filters => switch (role) {
    UserRole.employee => const [TicketFilter.active, TicketFilter.resolved, TicketFilter.all],
    UserRole.technician => const [TicketFilter.mine, TicketFilter.unassigned, TicketFilter.all],
    UserRole.manager => const [
      TicketFilter.unassigned,
      TicketFilter.active,
      TicketFilter.resolved,
      TicketFilter.all,
    ],
  };

  String _label(AppLocalizations l10n, TicketFilter f) => switch (f) {
    TicketFilter.active => l10n.ticketFilterActive,
    TicketFilter.mine => l10n.ticketFilterMine,
    TicketFilter.unassigned => l10n.ticketFilterUnassigned,
    TicketFilter.resolved => l10n.ticketFilterResolved,
    TicketFilter.all => l10n.ticketFilterAll,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthCubit>().state;
    final userId = auth is Authenticated ? auth.user.id : '';

    return BlocBuilder<TicketsCubit, TicketsState>(
      builder: (context, state) {
        final visible = state.visibleFor(userId);
        return Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(_label(l10n, f)),
                        selected: state.filter == f,
                        showCheckmark: false,
                        onSelected: (_) => context.read<TicketsCubit>().setFilter(f),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.loading) return const LoadingView();
                  if (state.error != null) {
                    return ErrorView(
                      message: state.error!,
                      onRetry: () => context.read<TicketsCubit>().start(),
                    );
                  }
                  if (visible.isEmpty) {
                    return EmptyView(
                      message: l10n.ticketsEmpty,
                      icon: Icons.task_alt_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => TicketRow(
                      ticket: visible[i],
                      showReporter: role != UserRole.employee,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
