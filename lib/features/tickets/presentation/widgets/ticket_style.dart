import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/ticket.dart';

extension TicketStatusStyle on TicketStatus {
  String label(AppLocalizations l10n) => switch (this) {
    TicketStatus.open => l10n.statusOpen,
    TicketStatus.assigned => l10n.statusAssigned,
    TicketStatus.inProgress => l10n.statusInProgress,
    TicketStatus.resolved => l10n.statusResolved,
  };

  Color get color => switch (this) {
    TicketStatus.open => AppColors.statusOpen,
    TicketStatus.assigned => AppColors.statusAssigned,
    TicketStatus.inProgress => AppColors.statusInProgress,
    TicketStatus.resolved => AppColors.statusResolved,
  };

  /// The four station names of the punch track, in order.
  static List<String> labels(AppLocalizations l10n) => [
    l10n.statusOpen,
    l10n.statusAssigned,
    l10n.statusInProgress,
    l10n.statusResolved,
  ];
}

extension TicketPriorityStyle on TicketPriority {
  String label(AppLocalizations l10n) => switch (this) {
    TicketPriority.low => l10n.priorityLow,
    TicketPriority.medium => l10n.priorityMedium,
    TicketPriority.high => l10n.priorityHigh,
  };

  Color get color => switch (this) {
    TicketPriority.low => AppColors.priorityLow,
    TicketPriority.medium => AppColors.priorityMedium,
    TicketPriority.high => AppColors.priorityHigh,
  };

  int get bars => index + 1;
}

/// Three little bars (1, 2 or 3 filled) plus the word, so priority
/// reads without color.
class PriorityMark extends StatelessWidget {
  const PriorityMark(this.priority, {super.key});

  final TicketPriority priority;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = Color.alphaBlend(
      theme.colorScheme.onSurface.withValues(alpha: 0.25),
      priority.color,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 4,
            height: 6.0 + i * 3,
            margin: const EdgeInsetsDirectional.only(end: 2),
            decoration: BoxDecoration(
              color: i < priority.bars ? color : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          priority.label(l10n).toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// "5 min ago", "3 h ago", "2 d ago" in the app language.
String timeAgo(AppLocalizations l10n, DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return l10n.justNow;
  if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
  return l10n.daysAgo(diff.inDays);
}
