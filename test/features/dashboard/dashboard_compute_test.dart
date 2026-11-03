import 'package:flutter_test/flutter_test.dart';

import 'package:scandesk/features/assets/domain/asset.dart';
import 'package:scandesk/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:scandesk/features/tickets/domain/ticket.dart';

final now = DateTime(2026, 11, 3, 12);

Asset asset(String id, {AssetStatus status = AssetStatus.active}) => Asset(
  id: id,
  code: 'LAP-000$id',
  name: 'Laptop $id',
  category: AssetCategory.laptop,
  status: status,
);

Ticket ticket(
  String id,
  String assetId,
  TicketStatus status, {
  required DateTime created,
  DateTime? updated,
}) => Ticket(
  id: id,
  assetId: assetId,
  assetCode: 'LAP-000$assetId',
  assetName: 'Laptop $assetId',
  title: 'Problem $id',
  description: '',
  status: status,
  priority: TicketPriority.medium,
  reporterId: 'e',
  reporterName: 'E',
  createdAt: created,
  updatedAt: updated ?? created,
);

void main() {
  test('counts tickets per status', () {
    final data = DashboardCubit.compute(
      [
        ticket('1', '1', TicketStatus.open, created: now),
        ticket('2', '1', TicketStatus.open, created: now),
        ticket('3', '2', TicketStatus.inProgress, created: now),
        ticket('4', '2', TicketStatus.resolved, created: now.subtract(const Duration(days: 1)), updated: now),
      ],
      [asset('1'), asset('2')],
      const {},
      now: now,
    );
    expect(data.byStatus[TicketStatus.open], 2);
    expect(data.byStatus[TicketStatus.inProgress], 1);
    expect(data.byStatus[TicketStatus.resolved], 1);
    expect(data.openNow, 3);
  });

  test('overdue means unresolved and older than 24 hours', () {
    final data = DashboardCubit.compute(
      [
        ticket('1', '1', TicketStatus.open, created: now.subtract(const Duration(hours: 30))),
        ticket('2', '1', TicketStatus.open, created: now.subtract(const Duration(hours: 2))),
        ticket('3', '1', TicketStatus.resolved, created: now.subtract(const Duration(days: 5)), updated: now),
      ],
      [asset('1')],
      const {},
      now: now,
    );
    expect(data.overdue, 1);
  });

  test('average resolution time is in hours, null when nothing is resolved', () {
    final none = DashboardCubit.compute(
      [ticket('1', '1', TicketStatus.open, created: now)],
      [asset('1')],
      const {},
      now: now,
    );
    expect(none.avgResolutionHours, isNull);

    final some = DashboardCubit.compute(
      [
        ticket('1', '1', TicketStatus.resolved, created: now.subtract(const Duration(hours: 4)), updated: now),
        ticket('2', '1', TicketStatus.resolved, created: now.subtract(const Duration(hours: 8)), updated: now),
      ],
      [asset('1')],
      const {},
      now: now,
    );
    expect(some.avgResolutionHours, closeTo(6, 0.001));
  });

  test('reports per day covers seven days, oldest first', () {
    final data = DashboardCubit.compute(
      [
        ticket('1', '1', TicketStatus.open, created: DateTime(2026, 11, 3, 9)),
        ticket('2', '1', TicketStatus.open, created: DateTime(2026, 11, 3, 10)),
        ticket('3', '1', TicketStatus.open, created: DateTime(2026, 10, 30, 10)),
      ],
      [asset('1')],
      const {},
      now: now,
    );
    expect(data.reportsPerDay.length, 7);
    expect(data.reportsPerDay.first.day, DateTime(2026, 10, 28));
    expect(data.reportsPerDay.last.day, DateTime(2026, 11, 3));
    expect(data.reportsPerDay.last.count, 2);
    expect(data.reportsPerDay[2].count, 1);
  });

  test('most repaired devices are ranked by ticket count', () {
    final data = DashboardCubit.compute(
      [
        ticket('1', '1', TicketStatus.open, created: now),
        ticket('2', '2', TicketStatus.open, created: now),
        ticket('3', '2', TicketStatus.open, created: now),
        ticket('4', '2', TicketStatus.open, created: now),
      ],
      [asset('1'), asset('2', status: AssetStatus.inRepair)],
      const {'2': {3, 5}},
      now: now,
    );
    expect(data.mostRepaired.first.asset.id, '2');
    expect(data.mostRepaired.first.count, 3);
    expect(data.mostRepaired.first.punchedMonths, {3, 5});
    expect(data.assetsInRepair, 1);
    expect(data.totalAssets, 2);
  });
}
