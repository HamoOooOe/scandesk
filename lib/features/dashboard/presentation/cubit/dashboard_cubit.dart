import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../assets/domain/asset.dart';
import '../../../assets/domain/assets_repository.dart';
import '../../../tickets/domain/ticket.dart';
import '../../../tickets/domain/tickets_repository.dart';

/// A device with the number of tickets it has had.
class RepairCount extends Equatable {
  const RepairCount(this.asset, this.count, this.punchedMonths);

  final Asset asset;
  final int count;
  final Set<int> punchedMonths;

  @override
  List<Object?> get props => [asset, count, punchedMonths];
}

class DashboardData extends Equatable {
  const DashboardData({
    this.byStatus = const {},
    this.overdue = 0,
    this.avgResolutionHours,
    this.reportsPerDay = const [],
    this.mostRepaired = const [],
    this.totalAssets = 0,
    this.assetsInRepair = 0,
  });

  final Map<TicketStatus, int> byStatus;

  /// Unresolved tickets older than 24 hours.
  final int overdue;
  final double? avgResolutionHours;

  /// Tickets created per day, oldest day first, 7 entries.
  final List<({DateTime day, int count})> reportsPerDay;
  final List<RepairCount> mostRepaired;
  final int totalAssets;
  final int assetsInRepair;

  int get openNow =>
      (byStatus[TicketStatus.open] ?? 0) +
      (byStatus[TicketStatus.assigned] ?? 0) +
      (byStatus[TicketStatus.inProgress] ?? 0);

  @override
  List<Object?> get props => [byStatus, overdue, avgResolutionHours, reportsPerDay, mostRepaired, totalAssets, assetsInRepair];
}

class DashboardState extends Equatable {
  const DashboardState({this.loading = true, this.data = const DashboardData(), this.error});

  final bool loading;
  final DashboardData data;
  final String? error;

  @override
  List<Object?> get props => [loading, data, error];
}

/// Manager overview, computed from the live ticket stream plus the asset
/// list. Pure calculation lives in [compute] so it can be unit tested.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._tickets, this._assets) : super(const DashboardState());

  final TicketsRepository _tickets;
  final AssetsRepository _assets;
  StreamSubscription<List<Ticket>>? _subscription;

  Future<void> start() async {
    try {
      final assets = <Asset>[];
      var offset = 0;
      while (true) {
        final page = await _assets.list(offset: offset, limit: 100);
        assets.addAll(page.items);
        if (!page.hasMore) break;
        offset += 100;
      }
      _subscription?.cancel();
      _subscription = _tickets.watchTickets().listen((tickets) async {
        final months = await _tickets.punchedMonths(
          assetIds: assets.map((a) => a.id),
          year: DateTime.now().year,
        );
        if (isClosed) return;
        emit(DashboardState(loading: false, data: compute(tickets, assets, months)));
      });
    } on Failure catch (failure) {
      emit(DashboardState(loading: false, error: failure.message));
    }
  }

  static DashboardData compute(
    List<Ticket> tickets,
    List<Asset> assets,
    Map<String, Set<int>> punches, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final byStatus = <TicketStatus, int>{for (final s in TicketStatus.values) s: 0};
    var overdue = 0;
    final resolvedHours = <double>[];
    final perAsset = <String, int>{};

    for (final t in tickets) {
      byStatus[t.status] = (byStatus[t.status] ?? 0) + 1;
      perAsset[t.assetId] = (perAsset[t.assetId] ?? 0) + 1;
      if (t.isClosed) {
        resolvedHours.add(t.updatedAt.difference(t.createdAt).inMinutes / 60);
      } else if (current.difference(t.createdAt) > const Duration(hours: 24)) {
        overdue++;
      }
    }

    final today = DateTime(current.year, current.month, current.day);
    // Days are built from the calendar date, not by subtracting 24 hours:
    // across a daylight-saving change "24 hours ago" is the wrong day.
    final perDay = [
      for (var i = 6; i >= 0; i--)
        (
          day: DateTime(today.year, today.month, today.day - i),
          count: tickets.where((t) {
            final d = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
            return d == DateTime(today.year, today.month, today.day - i);
          }).length,
        ),
    ];

    final byId = {for (final a in assets) a.id: a};
    final top = perAsset.entries.where((e) => byId.containsKey(e.key)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DashboardData(
      byStatus: byStatus,
      overdue: overdue,
      avgResolutionHours: resolvedHours.isEmpty
          ? null
          : resolvedHours.reduce((a, b) => a + b) / resolvedHours.length,
      reportsPerDay: perDay,
      mostRepaired: [
        for (final e in top.take(4))
          RepairCount(byId[e.key]!, e.value, punches[e.key] ?? const {}),
      ],
      totalAssets: assets.length,
      assetsInRepair: assets.where((a) => a.status == AssetStatus.inRepair).length,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
