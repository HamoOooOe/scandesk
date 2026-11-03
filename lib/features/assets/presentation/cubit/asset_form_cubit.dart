import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/asset.dart';
import '../../domain/assets_repository.dart';

enum AssetFormStatus { loading, editing, saving, saved, error }

class AssetFormState extends Equatable {
  const AssetFormState({
    this.status = AssetFormStatus.loading,
    this.asset = const Asset.draft(),
    this.sites = const [],
    this.locations = const [],
    this.error,
  });

  final AssetFormStatus status;
  final Asset asset;
  final List<Site> sites;
  final List<Location> locations;
  final String? error;

  AssetFormState copyWith({
    AssetFormStatus? status,
    Asset? asset,
    List<Site>? sites,
    List<Location>? locations,
    String? error,
  }) {
    return AssetFormState(
      status: status ?? this.status,
      asset: asset ?? this.asset,
      sites: sites ?? this.sites,
      locations: locations ?? this.locations,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, asset, sites, locations, error];
}

/// Add or edit one asset. New assets get their code from the repository
/// when they are saved (for example `LAP-0007`).
class AssetFormCubit extends Cubit<AssetFormState> {
  AssetFormCubit(this._assets, this._sites) : super(const AssetFormState());

  final AssetsRepository _assets;
  final SitesRepository _sites;

  Future<void> load({String? assetId}) async {
    try {
      final sites = await _sites.sites();
      final locations = await _sites.locations();
      final asset = assetId == null ? null : await _assets.getById(assetId);
      emit(
        AssetFormState(
          status: AssetFormStatus.editing,
          asset: asset ?? Asset.draft(siteId: sites.firstOrNull?.id),
          sites: sites,
          locations: locations,
        ),
      );
    } on Failure catch (failure) {
      emit(AssetFormState(status: AssetFormStatus.error, error: failure.message));
    }
  }

  Future<void> save(Asset asset) async {
    emit(state.copyWith(status: AssetFormStatus.saving, asset: asset));
    try {
      final saved = await _assets.save(asset);
      emit(state.copyWith(status: AssetFormStatus.saved, asset: saved));
    } on Failure catch (failure) {
      emit(state.copyWith(status: AssetFormStatus.editing, error: failure.message));
    }
  }
}
