import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../tickets/domain/tickets_repository.dart';
import '../../domain/asset.dart';
import '../../domain/assets_repository.dart';

enum AssetsListStatus { loading, loaded, loadingMore, error }

class AssetsListState extends Equatable {
  const AssetsListState({
    this.status = AssetsListStatus.loading,
    this.items = const [],
    this.query = const AssetQuery(),
    this.hasMore = false,
    this.punches = const {},
    this.error,
  });

  final AssetsListStatus status;
  final List<Asset> items;
  final AssetQuery query;
  final bool hasMore;

  /// Punched months this year, per asset id (for the ring on each row).
  final Map<String, Set<int>> punches;
  final String? error;

  AssetsListState copyWith({
    AssetsListStatus? status,
    List<Asset>? items,
    AssetQuery? query,
    bool? hasMore,
    Map<String, Set<int>>? punches,
    String? error,
  }) {
    return AssetsListState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      punches: punches ?? this.punches,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, items, query, hasMore, punches, error];
}

/// Asset list with search, filters and infinite scroll (20 per page).
class AssetsListCubit extends Cubit<AssetsListState> {
  AssetsListCubit(this._assets, this._tickets) : super(const AssetsListState());

  static const pageSize = 20;

  final AssetsRepository _assets;
  final TicketsRepository _tickets;

  // Each request gets a number; an answer that arrives after a newer
  // request was made is ignored (typing fast must not show old results).
  int _request = 0;

  Future<void> load() => _fetch(state.query, reset: true);

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == AssetsListStatus.loadingMore) return;
    await _fetch(state.query, reset: false);
  }

  void setText(String text) => _apply(state.query.copyWith(text: text));
  void setStatus(AssetStatus? status) => _apply(
    status == null ? state.query.copyWith(clearStatus: true) : state.query.copyWith(status: status),
  );
  void setCategory(AssetCategory? category) => _apply(
    category == null ? state.query.copyWith(clearCategory: true) : state.query.copyWith(category: category),
  );
  void setSite(String? siteId) => _apply(
    siteId == null ? state.query.copyWith(clearSite: true) : state.query.copyWith(siteId: siteId),
  );
  void clearFilters() => _apply(AssetQuery(text: state.query.text));

  void _apply(AssetQuery query) {
    if (query == state.query) return;
    _fetch(query, reset: true);
  }

  Future<void> _fetch(AssetQuery query, {required bool reset}) async {
    final id = ++_request;
    emit(
      state.copyWith(
        query: query,
        status: reset ? AssetsListStatus.loading : AssetsListStatus.loadingMore,
        items: reset ? const [] : state.items,
      ),
    );
    try {
      final page = await _assets.list(
        query: query,
        offset: reset ? 0 : state.items.length,
        limit: pageSize,
      );
      if (id != _request) return;
      final items = reset ? page.items : [...state.items, ...page.items];
      final months = await _tickets.punchedMonths(
        assetIds: page.items.map((a) => a.id),
        year: DateTime.now().year,
      );
      if (id != _request) return;
      emit(
        state.copyWith(
          status: AssetsListStatus.loaded,
          items: items,
          hasMore: page.hasMore,
          punches: {...(reset ? const {} : state.punches), ...months},
        ),
      );
    } on Failure catch (failure) {
      if (id != _request) return;
      emit(state.copyWith(status: AssetsListStatus.error, error: failure.message));
    }
  }
}
