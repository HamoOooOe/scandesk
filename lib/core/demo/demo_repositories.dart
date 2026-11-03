import 'dart:async';

import '../../features/assets/domain/asset.dart';
import '../../features/assets/domain/assets_repository.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/tickets/domain/ticket.dart';
import '../../features/tickets/domain/tickets_repository.dart';
import '../../features/users/domain/user_profile.dart';
import '../../features/users/domain/users_repository.dart';
import '../errors/failures.dart';
import 'demo_store.dart';

/// Pretends to be a network: a short pause before each answer, so
/// loading states and animations are visible in demo mode.
Future<void> _latency([int ms = 220]) => Future<void>.delayed(Duration(milliseconds: ms));

/// Demo login: three built-in accounts, any password with 6+ characters.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository();

  AppUser? current;
  final StreamController<void> _signedOut = StreamController<void>.broadcast();

  @override
  Future<AppUser?> getCurrentUser() async => current;

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await _latency(450);
    final user = [DemoStore.employee, DemoStore.technician, DemoStore.manager]
        .where((u) => u.email == email.trim().toLowerCase())
        .firstOrNull;
    if (user == null) throw const AuthFailure('Wrong email or password');
    return current = user;
  }

  @override
  Future<void> signUp({required String fullName, required String email, required String password}) async {
    await _latency(450);
  }

  @override
  Stream<void> get onSignedOut => _signedOut.stream;

  @override
  Stream<void> get onPasswordRecovery => const Stream<void>.empty();

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> sendPasswordReset(String email) async => _latency();

  @override
  Future<void> signOut() async {
    current = null;
  }
}

class DemoAssetsRepository implements AssetsRepository {
  DemoAssetsRepository(this._store);

  final DemoStore _store;

  @override
  Future<AssetPage> list({AssetQuery query = const AssetQuery(), int offset = 0, int limit = 20}) async {
    await _latency(160);
    final text = query.text.trim().toLowerCase();
    final all = _store.assets.where((a) {
      if (query.status != null && a.status != query.status) return false;
      if (query.category != null && a.category != query.category) return false;
      if (query.siteId != null && a.siteId != query.siteId) return false;
      if (text.isEmpty) return true;
      return a.code.toLowerCase().contains(text) ||
          a.name.toLowerCase().contains(text) ||
          a.serial.toLowerCase().contains(text) ||
          a.assignedTo.toLowerCase().contains(text);
    }).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    final end = (offset + limit).clamp(0, all.length);
    return AssetPage(items: all.sublist(offset.clamp(0, all.length), end), hasMore: end < all.length);
  }

  @override
  Future<Asset?> getById(String id) async => _store.assets.where((a) => a.id == id).firstOrNull;

  @override
  Future<Asset?> getByCode(String code) async {
    final wanted = code.trim().toUpperCase();
    return _store.assets.where((a) => a.code == wanted).firstOrNull;
  }

  @override
  Future<Asset> save(Asset asset) async {
    await _latency();
    if (asset.isNew) {
      final saved = Asset(
        id: _store.newId('a'),
        code: _store.nextCode(asset.category),
        name: asset.name,
        category: asset.category,
        status: asset.status,
        brand: asset.brand,
        model: asset.model,
        serial: asset.serial,
        siteId: asset.siteId,
        locationId: asset.locationId,
        assignedTo: asset.assignedTo,
        purchaseDate: asset.purchaseDate,
        warrantyUntil: asset.warrantyUntil,
        notes: asset.notes,
      );
      _store.assets.add(saved);
      return saved;
    }
    final index = _store.assets.indexWhere((a) => a.id == asset.id);
    if (index >= 0) _store.assets[index] = asset;
    return asset;
  }

  @override
  Future<void> delete(String id) async {
    _store.assets.removeWhere((a) => a.id == id);
  }
}

class DemoSitesRepository implements SitesRepository {
  DemoSitesRepository(this._store);

  final DemoStore _store;

  @override
  Future<List<Site>> sites() async => List.of(_store.sites);

  @override
  Future<List<Location>> locations({String? siteId}) async =>
      _store.locations.where((l) => siteId == null || l.siteId == siteId).toList();

  @override
  Future<Site> saveSite(Site site) async {
    await _latency(120);
    if (site.id.isEmpty) {
      final saved = Site(id: _store.newId('s'), name: site.name, city: site.city);
      _store.sites.add(saved);
      return saved;
    }
    final i = _store.sites.indexWhere((s) => s.id == site.id);
    if (i >= 0) _store.sites[i] = site;
    return site;
  }

  @override
  Future<void> deleteSite(String id) async {
    _store.sites.removeWhere((s) => s.id == id);
    _store.locations.removeWhere((l) => l.siteId == id);
  }

  @override
  Future<Location> saveLocation(Location location) async {
    await _latency(120);
    if (location.id.isEmpty) {
      final saved = Location(id: _store.newId('l'), siteId: location.siteId, name: location.name);
      _store.locations.add(saved);
      return saved;
    }
    final i = _store.locations.indexWhere((l) => l.id == location.id);
    if (i >= 0) _store.locations[i] = location;
    return location;
  }

  @override
  Future<void> deleteLocation(String id) async {
    _store.locations.removeWhere((l) => l.id == id);
  }
}

class DemoTicketsRepository implements TicketsRepository {
  DemoTicketsRepository(this._store, this._auth);

  final DemoStore _store;
  final DemoAuthRepository _auth;

  AppUser get _me => _auth.current ?? DemoStore.manager;

  List<Ticket> _visible() {
    final list = _store.tickets.where((t) => _me.role != UserRole.employee || t.reporterId == _me.id).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Stream<List<Ticket>> watchTickets() {
    // An explicit controller (instead of an async* generator) so that
    // cancelling the subscription is immediate and releases the listener.
    late final StreamController<List<Ticket>> controller;
    StreamSubscription<void>? changes;
    controller = StreamController<List<Ticket>>(
      onListen: () {
        controller.add(_visible());
        changes = _store.changes.listen((_) => controller.add(_visible()));
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<Ticket?> getById(String id) async => _store.tickets.where((t) => t.id == id).firstOrNull;

  Ticket _replace(String id, Ticket Function(Ticket) change) {
    final i = _store.tickets.indexWhere((t) => t.id == id);
    if (i < 0) throw const ServerFailure('Ticket not found');
    final updated = change(_store.tickets[i]);
    _store.tickets[i] = updated;
    _store.notifyChanged();
    return updated;
  }

  @override
  Future<Ticket> create({
    required String assetId,
    required String title,
    required String description,
    required TicketPriority priority,
    List<String> photoPaths = const [],
  }) async {
    await _latency(500);
    final asset = _store.assets.firstWhere((a) => a.id == assetId);
    final now = DateTime.now();
    final ticket = Ticket(
      id: _store.newId('t'),
      assetId: asset.id,
      assetCode: asset.code,
      assetName: asset.name,
      title: title,
      description: description,
      status: TicketStatus.open,
      priority: priority,
      reporterId: _me.id,
      reporterName: _me.fullName,
      createdAt: now,
      updatedAt: now,
      photoUrls: photoPaths,
    );
    _store.tickets.add(ticket);
    _store.notifyChanged();
    return ticket;
  }

  @override
  Future<Ticket> assign({required String ticketId, required String assigneeId}) async {
    await _latency(300);
    final who = _store.staff.firstWhere((s) => s.id == assigneeId);
    return _replace(
      ticketId,
      (t) => t.copyWith(
        status: TicketStatus.assigned,
        assigneeId: who.id,
        assigneeName: who.name,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Ticket> start(String ticketId) async {
    await _latency(300);
    return _replace(ticketId, (t) => t.copyWith(status: TicketStatus.inProgress, updatedAt: DateTime.now()));
  }

  @override
  Future<Ticket> resolve(String ticketId) async {
    await _latency(300);
    return _replace(ticketId, (t) => t.copyWith(status: TicketStatus.resolved, updatedAt: DateTime.now()));
  }

  @override
  Future<WorkLog> addWorkLog({
    required String ticketId,
    required String note,
    int minutes = 0,
    String parts = '',
  }) async {
    await _latency(300);
    final ticket = _store.tickets.firstWhere((t) => t.id == ticketId);
    final log = WorkLog(
      id: _store.newId('wl'),
      ticketId: ticketId,
      assetId: ticket.assetId,
      authorName: _me.fullName,
      note: note,
      minutes: minutes,
      parts: parts,
      createdAt: DateTime.now(),
    );
    _store.logs.add(log);
    _replace(ticketId, (t) => t.copyWith(updatedAt: DateTime.now()));
    return log;
  }

  @override
  Future<List<WorkLog>> workLogsForTicket(String ticketId) async =>
      _store.logs.where((l) => l.ticketId == ticketId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<WorkLog>> workLogsForAsset(String assetId) async =>
      _store.logs.where((l) => l.assetId == assetId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<StaffMember>> technicians() async => _store.staff;

  @override
  Future<Map<String, Set<int>>> punchedMonths({
    required Iterable<String> assetIds,
    required int year,
  }) async {
    final wanted = assetIds.toSet();
    final result = <String, Set<int>>{};
    for (final log in _store.logs) {
      if (log.createdAt.year == year && wanted.contains(log.assetId)) {
        result.putIfAbsent(log.assetId, () => <int>{}).add(log.createdAt.month);
      }
    }
    return result;
  }
}

class DemoUsersRepository implements UsersRepository {
  DemoUsersRepository(this._store);

  final DemoStore _store;

  @override
  Future<List<UserProfile>> getUsers() async {
    await _latency(160);
    return List.of(_store.profiles);
  }

  @override
  Future<void> changeRole({required String userId, required UserRole role}) async {
    await _latency(200);
    final i = _store.profiles.indexWhere((p) => p.id == userId);
    if (i >= 0) _store.profiles[i] = _store.profiles[i].copyWith(role: role);
  }
}
