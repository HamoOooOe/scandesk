import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/asset.dart';
import '../../domain/assets_repository.dart';

class SitesState extends Equatable {
  const SitesState({
    this.loading = true,
    this.sites = const [],
    this.locations = const [],
    this.error,
  });

  final bool loading;
  final List<Site> sites;
  final List<Location> locations;
  final String? error;

  List<Location> locationsOf(String siteId) =>
      locations.where((l) => l.siteId == siteId).toList();

  @override
  List<Object?> get props => [loading, sites, locations, error];
}

/// Manager screen state: sites with the locations inside them.
class SitesCubit extends Cubit<SitesState> {
  SitesCubit(this._repository) : super(const SitesState());

  final SitesRepository _repository;

  Future<void> load() async {
    try {
      final sites = await _repository.sites();
      final locations = await _repository.locations();
      emit(SitesState(loading: false, sites: sites, locations: locations));
    } on Failure catch (failure) {
      emit(SitesState(loading: false, error: failure.message));
    }
  }

  Future<void> saveSite(Site site) async {
    await _guard(() => _repository.saveSite(site));
  }

  Future<void> deleteSite(String id) async {
    await _guard(() => _repository.deleteSite(id));
  }

  Future<void> saveLocation(Location location) async {
    await _guard(() => _repository.saveLocation(location));
  }

  Future<void> deleteLocation(String id) async {
    await _guard(() => _repository.deleteLocation(id));
  }

  Future<void> _guard(Future<Object?> Function() action) async {
    try {
      await action();
      await load();
    } on Failure catch (failure) {
      emit(SitesState(
        loading: false,
        sites: state.sites,
        locations: state.locations,
        error: failure.message,
      ));
    }
  }
}
