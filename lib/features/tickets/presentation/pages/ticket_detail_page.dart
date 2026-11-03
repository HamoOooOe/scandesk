import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/legend.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/punch_track.dart';
import '../../../../core/widgets/tag_card.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/ticket.dart';
import '../../domain/ticket_rules.dart';
import '../cubit/ticket_detail_cubit.dart';
import '../cubit/tickets_cubit.dart';
import '../widgets/ticket_style.dart';

class TicketDetailPage extends StatefulWidget {
  const TicketDetailPage({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  @override
  void initState() {
    super.initState();
    // Opening a ticket clears its "updated" tint in the list.
    sl<SeenTickets>().markOpened(widget.ticketId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TicketDetailCubit>()..load(widget.ticketId),
      child: const _TicketView(),
    );
  }
}

class _TicketView extends StatelessWidget {
  const _TicketView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthCubit>().state;
    final user = auth is Authenticated ? auth.user : null;

    return BlocConsumer<TicketDetailCubit, TicketDetailState>(
      listenWhen: (a, b) => b.notice != null || (b.error != null && a.error != b.error),
      listener: (context, state) {
        final text = state.notice != null ? l10n.workLogged : state.error;
        if (text != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        }
      },
      builder: (context, state) {
        final ticket = state.ticket;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.ticketDetails)),
          body: state.loading
              ? const LoadingView()
              : ticket == null
              ? const EmptyView(icon: Icons.search_off_outlined)
              : _Body(state: state, ticket: ticket),
          bottomNavigationBar: ticket == null || user == null
              ? null
              : _Actions(state: state, ticket: ticket, user: user),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.ticket});

  final TicketDetailState state;
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TagCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: PunchTrack(
            stage: ticket.status.stage,
            resolved: ticket.isClosed,
            labels: TicketStatusStyle.labels(l10n),
            accent: ticket.status.color,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(ticket.assetCode, style: AppTheme.mono(context, size: 13)),
            const SizedBox(width: 12),
            PriorityMark(ticket.priority),
            const Spacer(),
            Text(
              timeAgo(l10n, ticket.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(ticket.title, style: theme.textTheme.headlineSmall),
        if (ticket.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(ticket.description, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 16),
        TagCard(
          hole: false,
          onTap: () => context.push(Routes.assetPath(ticket.assetId)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ticket.assetCode, style: AppTheme.mono(context, size: 12)),
                    const SizedBox(height: 2),
                    Text(ticket.assetName, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 20,
          runSpacing: 4,
          children: [
            Text(l10n.reportedBy(ticket.reporterName), style: theme.textTheme.bodyMedium),
            Text(
              ticket.assigneeName == null
                  ? l10n.notAssignedYet
                  : l10n.assignedToName(ticket.assigneeName!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ticket.assigneeName == null ? scheme.tertiary : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (ticket.photoUrls.isNotEmpty) ...[
          const SizedBox(height: 20),
          Legend(l10n.photosTitle),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ticket.photoUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final path = ticket.photoUrls[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: path.startsWith('http')
                        ? CachedNetworkImage(imageUrl: path, fit: BoxFit.cover)
                        : Image.file(File(path), fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 24),
        Legend(l10n.workLogTitle),
        const SizedBox(height: 8),
        if (state.logs.isEmpty)
          Text(
            l10n.noWorkYet,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          for (final log in state.logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TagCard(
                hole: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.note, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 6),
                    Text(
                      [
                        log.authorName,
                        if (log.minutes > 0) l10n.minutesShort(log.minutes),
                        timeAgo(l10n, log.createdAt),
                      ].join('  ·  '),
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (log.parts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        log.parts,
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

/// The one thing this person can do next, at the bottom where a thumb is.
class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.ticket, required this.user});

  final TicketDetailState state;
  final Ticket ticket;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TicketDetailCubit>();
    final busy = state.busy;

    final children = <Widget>[];
    if (TicketRules.canAssign(user.role, ticket)) {
      children.add(
        FilledButton.icon(
          onPressed: busy ? null : () => _pickAssignee(context),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text(l10n.assignTo),
        ),
      );
    }
    if (TicketRules.canStart(user.role, user.id, ticket)) {
      children.add(
        FilledButton.icon(
          onPressed: busy ? null : cubit.start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.startWork),
        ),
      );
    }
    if (TicketRules.canLogWork(user.role, user.id, ticket)) {
      final canResolve = TicketRules.canResolve(user.role, user.id, ticket);
      children.add(
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _logWork(context),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(l10n.logWork),
              ),
            ),
            if (canResolve) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : cubit.resolve,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l10n.resolveTicket),
                ),
              ),
            ],
          ],
        ),
      );
    }
    if (children.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }

  Future<void> _pickAssignee(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TicketDetailCubit>();
    final picked = await showModalBottomSheet<StaffMember>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(l10n.assignTo, style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            for (final member in state.staff)
              ListTile(
                leading: CircleAvatar(child: Text(member.name.characters.first)),
                title: Text(member.name),
                onTap: () => Navigator.pop(context, member),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) await cubit.assign(picked.id);
  }

  Future<void> _logWork(BuildContext context) async {
    final cubit = context.read<TicketDetailCubit>();
    final result = await showModalBottomSheet<({String note, int minutes, String parts})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _LogWorkSheet(),
    );
    if (result != null) {
      await cubit.logWork(note: result.note, minutes: result.minutes, parts: result.parts);
    }
  }
}

class _LogWorkSheet extends StatefulWidget {
  const _LogWorkSheet();

  @override
  State<_LogWorkSheet> createState() => _LogWorkSheetState();
}

class _LogWorkSheetState extends State<_LogWorkSheet> {
  final _note = TextEditingController();
  final _minutes = TextEditingController();
  final _parts = TextEditingController();
  final _key = GlobalKey<FormState>();

  @override
  void dispose() {
    _note.dispose();
    _minutes.dispose();
    _parts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.logWork, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(labelText: l10n.workNote),
              validator: (v) => (v ?? '').trim().isEmpty ? l10n.requiredField : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minutes,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.minutesSpent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _parts,
                    decoration: InputDecoration(labelText: l10n.partsUsed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (_key.currentState?.validate() ?? false) {
                  Navigator.pop(context, (
                    note: _note.text.trim(),
                    minutes: int.tryParse(_minutes.text.trim()) ?? 0,
                    parts: _parts.text.trim(),
                  ));
                }
              },
              child: Text(l10n.saveAction),
            ),
          ],
        ),
      ),
    );
  }
}
