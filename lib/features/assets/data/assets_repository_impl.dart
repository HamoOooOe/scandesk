import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/guard.dart';
import '../domain/asset.dart';
import '../domain/assets_repository.dart';

/// Supabase implementation of [AssetsRepository] on the `assets` table.
/// Row-level security lets everyone read and only managers write.
class AssetsRepositoryImpl implements AssetsRepository {
  AssetsRepositoryImpl(this._client);

  final SupabaseClient _client;

  static Asset _fromRow(Map<String, dynamic> r) => Asset(
    id: r['id'] as String,
    code: r['code'] as String,
    name: (r['name'] as String?) ?? '',
    category: AssetCategory.fromValue(r['category'] as String?),
    status: AssetStatus.fromValue(r['status'] as String?),
    brand: (r['brand'] as String?) ?? '',
    model: (r['model'] as String?) ?? '',
    serial: (r['serial'] as String?) ?? '',
    siteId: r['site_id'] as String?,
    locationId: r['location_id'] as String?,
    assignedTo: (r['assigned_to'] as String?) ?? '',
    purchaseDate: _date(r['purchase_date']),
    warrantyUntil: _date(r['warranty_until']),
    notes: (r['notes'] as String?) ?? '',
  );

  static DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

  static String? _dateOnly(DateTime? d) => d?.toIso8601String().split('T').first;

  @override
  Future<AssetPage> list({AssetQuery query = const AssetQuery(), int offset = 0, int limit = 20}) {
    return guardSupabase(() async {
      var request = _client.from('assets').select();
      if (query.status != null) request = request.eq('status', query.status!.value);
      if (query.category != null) request = request.eq('category', query.category!.name);
      if (query.siteId != null) request = request.eq('site_id', query.siteId!);
      final text = query.text.trim().replaceAll(RegExp(r'[,()%]'), ' ');
      if (text.isNotEmpty) {
        request = request.or(
          'code.ilike.%$text%,name.ilike.%$text%,serial.ilike.%$text%,assigned_to.ilike.%$text%',
        );
      }
      // Ask for one extra row to know whether another page exists.
      final rows = await request.order('code').range(offset, offset + limit);
      final items = rows.take(limit).map(_fromRow).toList();
      return AssetPage(items: items, hasMore: rows.length > limit);
    });
  }

  @override
  Future<Asset?> getById(String id) => guardSupabase(() async {
    final row = await _client.from('assets').select().eq('id', id).maybeSingle();
    return row == null ? null : _fromRow(row);
  });

  @override
  Future<Asset?> getByCode(String code) => guardSupabase(() async {
    final row = await _client.from('assets').select().eq('code', code.trim().toUpperCase()).maybeSingle();
    return row == null ? null : _fromRow(row);
  });

  @override
  Future<Asset> save(Asset asset) => guardSupabase(() async {
    final values = {
      'name': asset.name,
      'category': asset.category.name,
      'status': asset.status.value,
      'brand': asset.brand,
      'model': asset.model,
      'serial': asset.serial,
      'site_id': asset.siteId,
      'location_id': asset.locationId,
      'assigned_to': asset.assignedTo,
      'purchase_date': _dateOnly(asset.purchaseDate),
      'warranty_until': _dateOnly(asset.warrantyUntil),
      'notes': asset.notes,
    };
    // For a new asset the database trigger fills in the code.
    final rows = asset.isNew
        ? await _client.from('assets').insert(values).select()
        : await _client.from('assets').update(values).eq('id', asset.id).select();
    // RLS turns a blocked write into "zero rows", not an error.
    if (rows.isEmpty) throw const PermissionFailure();
    return _fromRow(rows.first);
  });

  @override
  Future<void> delete(String id) => guardSupabase(() async {
    final rows = await _client.from('assets').delete().eq('id', id).select('id');
    if (rows.isEmpty) throw const PermissionFailure();
  });
}

/// Supabase implementation of [SitesRepository].
class SitesRepositoryImpl implements SitesRepository {
  SitesRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Site>> sites() => guardSupabase(() async {
    final rows = await _client.from('sites').select().order('name');
    return [
      for (final r in rows)
        Site(id: r['id'] as String, name: r['name'] as String, city: (r['city'] as String?) ?? ''),
    ];
  });

  @override
  Future<List<Location>> locations({String? siteId}) => guardSupabase(() async {
    var request = _client.from('locations').select();
    if (siteId != null) request = request.eq('site_id', siteId);
    final rows = await request.order('name');
    return [
      for (final r in rows)
        Location(id: r['id'] as String, siteId: r['site_id'] as String, name: r['name'] as String),
    ];
  });

  @override
  Future<Site> saveSite(Site site) => guardSupabase(() async {
    final values = {'name': site.name, 'city': site.city};
    final rows = site.id.isEmpty
        ? await _client.from('sites').insert(values).select()
        : await _client.from('sites').update(values).eq('id', site.id).select();
    if (rows.isEmpty) throw const PermissionFailure();
    final r = rows.first;
    return Site(id: r['id'] as String, name: r['name'] as String, city: (r['city'] as String?) ?? '');
  });

  @override
  Future<void> deleteSite(String id) => guardSupabase(() async {
    final rows = await _client.from('sites').delete().eq('id', id).select('id');
    if (rows.isEmpty) throw const PermissionFailure();
  });

  @override
  Future<Location> saveLocation(Location location) => guardSupabase(() async {
    final values = {'site_id': location.siteId, 'name': location.name};
    final rows = location.id.isEmpty
        ? await _client.from('locations').insert(values).select()
        : await _client.from('locations').update(values).eq('id', location.id).select();
    if (rows.isEmpty) throw const PermissionFailure();
    final r = rows.first;
    return Location(id: r['id'] as String, siteId: r['site_id'] as String, name: r['name'] as String);
  });

  @override
  Future<void> deleteLocation(String id) => guardSupabase(() async {
    final rows = await _client.from('locations').delete().eq('id', id).select('id');
    if (rows.isEmpty) throw const PermissionFailure();
  });
}
