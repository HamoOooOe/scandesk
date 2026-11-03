import 'asset.dart';

/// Contract for assets. Every method throws a `Failure` on error.
abstract interface class AssetsRepository {
  /// One page of assets matching [query], newest code first.
  Future<AssetPage> list({
    AssetQuery query = const AssetQuery(),
    int offset = 0,
    int limit = 20,
  });

  Future<Asset?> getById(String id);

  /// Looks an asset up by the code printed on its sticker.
  Future<Asset?> getByCode(String code);

  /// Creates the asset (and its generated code) when it is new, otherwise
  /// updates it. Returns the saved asset.
  Future<Asset> save(Asset asset);

  Future<void> delete(String id);
}

/// Contract for sites and the locations inside them.
abstract interface class SitesRepository {
  Future<List<Site>> sites();
  Future<List<Location>> locations({String? siteId});
  Future<Site> saveSite(Site site);
  Future<void> deleteSite(String id);
  Future<Location> saveLocation(Location location);
  Future<void> deleteLocation(String id);
}
