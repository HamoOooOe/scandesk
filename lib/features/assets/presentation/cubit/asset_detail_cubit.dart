import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../tickets/domain/ticket.dart';
import '../../../tickets/domain/tickets_repository.dart';
import '../../domain/asset.dart';
import '../../domain/assets_repository.dart';

enum AssetDetailStatus { loading, loaded, notFound, error }

class AssetDetailState extends Equatable {
  const AssetDetailState({
    this.status = AssetDetailStatus.loading,
    this.asset,
    this.siteName = '',
    this.locationName = '',
    this.history = const [],
    this.openTickets = const [],
    this.error,
  });

  final AssetDetailStatus status;
  final Asset? asset;
  final String siteName;
  final String locationName;

  /// Work logs, newest first.
  final List<WorkLog> history;
  final List<Ticket> openTickets;
  final String? error;

  /// Months of the current year that have a punch.
  Set<int> punchedMonths(int year) =>
      {for (final log in history) if (log.createdAt.year == year) log.createdAt.month};

  DateTime? get lastServiced => history.isEmpty ? null : history.first.createdAt;

  @override
  List<Object?> get props => [status, asset, siteName, locationName, history, openTickets, error];
}

/// One asset with everything the technician needs after a scan: its
/// details, repair history and tickets still open.
class AssetDetailCubit extends Cubit<AssetDetailState> {
  AssetDetailCubit(this._assets, this._tickets, this._sites)
    : super(const AssetDetailState());

  final AssetsRepository _assets;
  final TicketsRepository _tickets;
  final SitesRepository _sites;

  Future<void> load(String assetId) async {
    emit(const AssetDetailState());
    try {
      final asset = await _assets.getById(assetId);
      if (asset == null) {
        emit(const AssetDetailState(status: AssetDetailStatus.notFound));
        return;
      }
      final results = await Future.wait([
        _tickets.workLogsForAsset(asset.id),
        _tickets.watchTickets().first,
        _sites.sites(),
        _sites.locations(),
      ]);
      final history = results[0] as List<WorkLog>;
      final tickets = (results[1] as List<Ticket>)
          .where((t) => t.assetId == asset.id && !t.isClosed)
          .toList();
      final sites = results[2] as List<Site>;
      final locations = results[3] as List<Location>;
      emit(
        AssetDetailState(
          status: AssetDetailStatus.loaded,
          asset: asset,
          siteName: sites.where((s) => s.id == asset.siteId).firstOrNull?.name ?? '',
          locationName: locations.where((l) => l.id == asset.locationId).firstOrNull?.name ?? '',
          history: history,
          openTickets: tickets,
        ),
      );
    } on Failure catch (failure) {
      emit(AssetDetailState(status: AssetDetailStatus.error, error: failure.message));
    }
  }
}
