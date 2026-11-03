import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/legend.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/punch_ring.dart';
import '../../../../core/widgets/status_tag.dart';
import '../../../../core/widgets/tag_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../tickets/domain/ticket.dart';
import '../../../tickets/presentation/widgets/ticket_row.dart';
import '../cubit/asset_detail_cubit.dart';
import '../widgets/asset_style.dart';

/// Where a scan lands for technicians and managers: the device, its
/// service ring, what is open on it, and its repair history.
class AssetDetailPage extends StatelessWidget {
  const AssetDetailPage({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AssetDetailCubit>()..load(assetId),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthCubit>().state;
    final canEdit = auth is Authenticated && auth.user.role.canManageAssets;

    return BlocBuilder<AssetDetailCubit, AssetDetailState>(
      builder: (context, state) {
        final asset = state.asset;
        return Scaffold(
          appBar: AppBar(
            title: Text(asset?.code ?? ''),
            actions: [
              if (asset != null) ...[
                IconButton(
                  tooltip: l10n.showQr,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  onPressed: () => context.push(Routes.assetQrPath(asset.id)),
                ),
                if (canEdit)
                  IconButton(
                    tooltip: l10n.editAsset,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      await context.push(Routes.assetEditPath(asset.id));
                      if (context.mounted) context.read<AssetDetailCubit>().load(asset.id);
                    },
                  ),
              ],
            ],
          ),
          body: switch (state.status) {
            AssetDetailStatus.loading => const LoadingView(),
            AssetDetailStatus.notFound || AssetDetailStatus.error => EmptyView(
              message: l10n.assetGone,
              icon: Icons.search_off_outlined,
            ),
            AssetDetailStatus.loaded => _Content(state: state),
          },
          bottomNavigationBar: asset == null
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      border: Border(
                        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                    ),
                    child: FilledButton.icon(
                      onPressed: () => context.push(Routes.reportPath(asset.id)),
                      icon: const Icon(Icons.report_problem_outlined),
                      label: Text(l10n.reportTitle),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final AssetDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final asset = state.asset!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final now = DateTime.now();

    String field(String? v) => (v == null || v.isEmpty) ? '—' : v;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        TagCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              PunchRing(
                punchedMonths: state.punchedMonths(now.year),
                size: 148,
                year: now.year,
                currentMonth: now.month,
                showMonthNumbers: true,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 16),
                      child: Legend(l10n.serviceRecord),
                    ),
                    const SizedBox(height: 4),
                    Text(asset.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      state.lastServiced == null
                          ? l10n.neverServiced
                          : l10n.lastServicedOn(date.format(state.lastServiced!)),
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    StatusTag(
                      label: asset.status.label(l10n),
                      stage: asset.status.stage,
                      color: asset.status.color(scheme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TagCard(
          hole: false,
          child: Wrap(
            runSpacing: 16,
            children: [
              _Field(l10n.fieldCategory, asset.category.label(l10n)),
              _Field(l10n.fieldSerial, field(asset.serial), mono: true),
              _Field(l10n.fieldSite, field(state.siteName)),
              _Field(l10n.fieldLocation, field(state.locationName)),
              _Field(l10n.fieldAssignedTo, field(asset.assignedTo)),
              _Field(
                l10n.fieldWarranty,
                asset.warrantyUntil == null
                    ? '—'
                    : asset.underWarranty
                    ? date.format(asset.warrantyUntil!)
                    : l10n.warrantyExpired,
              ),
            ],
          ),
        ),
        if (state.openTickets.isNotEmpty) ...[
          const SizedBox(height: 24),
          Legend(l10n.openTicketsTitle),
          const SizedBox(height: 8),
          for (final t in state.openTickets)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: TicketRow(ticket: t)),
        ],
        const SizedBox(height: 24),
        Legend(l10n.repairHistory),
        const SizedBox(height: 8),
        if (state.history.isEmpty)
          Text(
            l10n.noHistory,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          for (var i = 0; i < state.history.length; i++)
            _HistoryEntry(
              log: state.history[i],
              isLast: i == state.history.length - 1,
              date: date,
            ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 32 - 32) / 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Legend(label),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: mono ? AppTheme.mono(context, size: 13) : theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// One entry of the repair history, hung on a rail like the punch track.
class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.log, required this.isLast, required this.date});

  final WorkLog log;
  final bool isLast;
  final DateFormat date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: scheme.onSurface, shape: BoxShape.circle),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: scheme.outlineVariant)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date.format(log.createdAt), style: theme.textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(log.note, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    [
                      log.authorName,
                      if (log.minutes > 0) l10n.minutesShort(log.minutes),
                    ].join('  ·  '),
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
