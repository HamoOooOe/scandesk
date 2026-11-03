import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/punch_track.dart';
import '../../../../core/widgets/status_tag.dart';
import '../../../../core/widgets/tag_card.dart';
import '../../domain/ticket.dart';
import '../cubit/tickets_cubit.dart';
import 'ticket_style.dart';

/// One ticket in a list: asset code, title, a punch track showing how far
/// it has come, and who has it. A ticket that changed since the user last
/// opened it stays tinted and says UPDATED.
class TicketRow extends StatelessWidget {
  const TicketRow({super.key, required this.ticket, this.showReporter = false});

  final Ticket ticket;
  final bool showReporter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final flagged = sl<SeenTickets>().isFlagged(ticket);
    final status = ticket.status;

    return TagCard(
      flagged: flagged,
      onTap: () => context.push(Routes.ticketPath(ticket.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 22),
            child: Row(
              children: [
                Text(ticket.assetCode, style: AppTheme.mono(context, size: 12)),
                const SizedBox(width: 10),
                if (flagged) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: scheme.tertiary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.ticketUpdated.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(),
                PriorityMark(ticket.priority),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ticket.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            showReporter ? '${ticket.assetName}  ·  ${ticket.reporterName}' : ticket.assetName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          PunchTrack(
            stage: status.stage,
            resolved: ticket.isClosed,
            labels: TicketStatusStyle.labels(l10n),
            accent: status.color,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              StatusTag(label: status.label(l10n), stage: status.stage, color: status.color),
              const Spacer(),
              Flexible(
                child: Text(
                  [
                    if (ticket.assigneeName != null) ticket.assigneeName!,
                    timeAgo(l10n, ticket.updatedAt),
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
