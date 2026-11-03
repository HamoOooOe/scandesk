import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/errors/guard.dart';
import '../domain/ticket.dart';
import '../domain/tickets_repository.dart';

/// Supabase implementation of [TicketsRepository].
///
/// Reads go through the `tickets_view` and `work_logs_view` views, which
/// add the asset code and people's names (an employee cannot read other
/// people's profiles directly, but may see the name on their own ticket).
/// Writes go to the `tickets` and `work_logs` tables; row-level security
/// and the status trigger enforce who may do what.
/// Changes arrive through Supabase Realtime on the `tickets` table.
class TicketsRepositoryImpl implements TicketsRepository {
  TicketsRepositoryImpl(this._client);

  static const _bucket = 'ticket-photos';

  final SupabaseClient _client;

  Future<Ticket> _toTicket(Map<String, dynamic> r) async {
    final paths = [for (final p in (r['photo_paths'] as List? ?? const [])) p as String];
    var urls = <String>[];
    if (paths.isNotEmpty) {
      urls = [
        for (final path in paths)
          await _client.storage.from(_bucket).createSignedUrl(path, 3600),
      ];
    }
    return Ticket(
      id: r['id'] as String,
      assetId: r['asset_id'] as String,
      assetCode: (r['asset_code'] as String?) ?? '',
      assetName: (r['asset_name'] as String?) ?? '',
      title: r['title'] as String,
      description: (r['description'] as String?) ?? '',
      status: TicketStatus.fromValue(r['status'] as String?),
      priority: TicketPriority.fromValue(r['priority'] as String?),
      reporterId: r['reporter_id'] as String,
      reporterName: (r['reporter_name'] as String?) ?? '',
      assigneeId: r['assignee_id'] as String?,
      assigneeName: r['assignee_name'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(r['updated_at'] as String).toLocal(),
      photoUrls: urls,
    );
  }

  Future<List<Ticket>> _fetchAll() async {
    final rows = await _client.from('tickets_view').select().order('updated_at', ascending: false);
    return Future.wait(rows.map(_toTicket));
  }

  @override
  Stream<List<Ticket>> watchTickets() async* {
    try {
      yield await _fetchAll();
      // The stream only tells us "something changed"; the view then gives
      // the full, joined rows.
      await for (final _ in _client.from('tickets').stream(primaryKey: ['id'])) {
        yield await _fetchAll();
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw const NetworkFailure();
    }
  }

  @override
  Future<Ticket?> getById(String id) => guardSupabase(() async {
    final row = await _client.from('tickets_view').select().eq('id', id).maybeSingle();
    return row == null ? null : _toTicket(row);
  });

  @override
  Future<Ticket> create({
    required String assetId,
    required String title,
    required String description,
    required TicketPriority priority,
    List<String> photoPaths = const [],
  }) => guardSupabase(() async {
    final inserted = await _client
        .from('tickets')
        .insert({
          'asset_id': assetId,
          'title': title,
          'description': description,
          'priority': priority.name,
        })
        .select('id')
        .single();
    final id = inserted['id'] as String;

    for (var i = 0; i < photoPaths.length; i++) {
      final path = '$id/$i.jpg';
      await _client.storage.from(_bucket).upload(path, File(photoPaths[i]));
      await _client.from('ticket_photos').insert({'ticket_id': id, 'path': path});
    }
    return (await getById(id))!;
  });

  Future<Ticket> _update(String id, Map<String, dynamic> values) async {
    final rows = await _client.from('tickets').update(values).eq('id', id).select('id');
    // RLS or the status trigger blocked it: zero rows come back.
    if (rows.isEmpty) throw const PermissionFailure();
    return (await getById(id))!;
  }

  @override
  Future<Ticket> assign({required String ticketId, required String assigneeId}) =>
      guardSupabase(() => _update(ticketId, {'assignee_id': assigneeId, 'status': 'assigned'}));

  @override
  Future<Ticket> start(String ticketId) =>
      guardSupabase(() => _update(ticketId, {'status': 'in_progress'}));

  @override
  Future<Ticket> resolve(String ticketId) =>
      guardSupabase(() => _update(ticketId, {'status': 'resolved'}));

  WorkLog _toLog(Map<String, dynamic> r) => WorkLog(
    id: r['id'] as String,
    ticketId: r['ticket_id'] as String,
    assetId: r['asset_id'] as String,
    authorName: (r['author_name'] as String?) ?? '',
    note: r['note'] as String,
    minutes: (r['minutes'] as int?) ?? 0,
    parts: (r['parts'] as String?) ?? '',
    createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
  );

  @override
  Future<WorkLog> addWorkLog({
    required String ticketId,
    required String note,
    int minutes = 0,
    String parts = '',
  }) => guardSupabase(() async {
    final ticket = await _client.from('tickets').select('asset_id').eq('id', ticketId).single();
    final row = await _client
        .from('work_logs')
        .insert({
          'ticket_id': ticketId,
          'asset_id': ticket['asset_id'],
          'note': note,
          'minutes': minutes,
          'parts': parts,
        })
        .select('id')
        .single();
    final full = await _client.from('work_logs_view').select().eq('id', row['id'] as String).single();
    return _toLog(full);
  });

  @override
  Future<List<WorkLog>> workLogsForTicket(String ticketId) => guardSupabase(() async {
    final rows = await _client
        .from('work_logs_view')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: false);
    return rows.map(_toLog).toList();
  });

  @override
  Future<List<WorkLog>> workLogsForAsset(String assetId) => guardSupabase(() async {
    final rows = await _client
        .from('work_logs_view')
        .select()
        .eq('asset_id', assetId)
        .order('created_at', ascending: false);
    return rows.map(_toLog).toList();
  });

  @override
  Future<List<StaffMember>> technicians() => guardSupabase(() async {
    final rows = await _client.from('profiles').select('id, full_name').eq('role', 'technician').order('full_name');
    return [for (final r in rows) StaffMember(id: r['id'] as String, name: (r['full_name'] as String?) ?? '')];
  });

  @override
  Future<Map<String, Set<int>>> punchedMonths({
    required Iterable<String> assetIds,
    required int year,
  }) => guardSupabase(() async {
    final ids = assetIds.toList();
    if (ids.isEmpty) return {};
    final rows = await _client
        .from('work_logs')
        .select('asset_id, created_at')
        .inFilter('asset_id', ids)
        .gte('created_at', DateTime(year).toUtc().toIso8601String())
        .lt('created_at', DateTime(year + 1).toUtc().toIso8601String());
    final result = <String, Set<int>>{};
    for (final r in rows) {
      final when = DateTime.parse(r['created_at'] as String).toLocal();
      result.putIfAbsent(r['asset_id'] as String, () => <int>{}).add(when.month);
    }
    return result;
  });
}
