import 'package:flutter_test/flutter_test.dart';

import 'package:scandesk/core/demo/demo_repositories.dart';
import 'package:scandesk/core/demo/demo_store.dart';
import 'package:scandesk/features/assets/domain/asset.dart';
import 'package:scandesk/features/tickets/domain/ticket.dart';

void main() {
  late DemoStore store;
  late DemoAuthRepository auth;

  setUp(() {
    store = DemoStore();
    auth = DemoAuthRepository();
  });

  group('assets', () {
    test('lists in pages and says when more remain', () async {
      final repo = DemoAssetsRepository(store);
      final first = await repo.list(limit: 20);
      expect(first.items.length, 20);
      expect(first.hasMore, isTrue);

      final rest = await repo.list(offset: 20, limit: 50);
      expect(first.items.length + rest.items.length, store.assets.length);
      expect(rest.hasMore, isFalse);
    });

    test('filters by category, status and text', () async {
      final repo = DemoAssetsRepository(store);
      final printers = await repo.list(
        query: const AssetQuery(category: AssetCategory.printer),
        limit: 100,
      );
      expect(printers.items, isNotEmpty);
      expect(printers.items.every((a) => a.category == AssetCategory.printer), isTrue);

      final byCode = await repo.list(query: const AssetQuery(text: 'lap-0003'));
      expect(byCode.items.single.code, 'LAP-0003');
    });

    test('a new asset gets the next code for its category', () async {
      final repo = DemoAssetsRepository(store);
      final before = store.assets.where((a) => a.category == AssetCategory.monitor).length;
      final saved = await repo.save(
        const Asset.draft(name: 'LG UltraFine', category: AssetCategory.monitor),
      );
      expect(saved.isNew, isFalse);
      expect(saved.code, 'MON-${(before + 1).toString().padLeft(4, '0')}');
      expect((await repo.getByCode('mon-${(before + 1).toString().padLeft(4, '0')}'))?.id, saved.id);
    });
  });

  group('tickets', () {
    test('an employee only sees their own tickets', () async {
      await auth.signIn(email: DemoStore.employee.email, password: 'secret1');
      final repo = DemoTicketsRepository(store, auth);
      final tickets = await repo.watchTickets().first;
      expect(tickets, isNotEmpty);
      expect(tickets.every((t) => t.reporterId == DemoStore.employee.id), isTrue);
    });

    test('a ticket moves open, assigned, in progress, resolved', () async {
      await auth.signIn(email: DemoStore.manager.email, password: 'secret1');
      final repo = DemoTicketsRepository(store, auth);
      final asset = store.assets.first;

      final created = await repo.create(
        assetId: asset.id,
        title: 'Screen is cracked',
        description: '',
        priority: TicketPriority.high,
      );
      expect(created.status, TicketStatus.open);

      final assigned = await repo.assign(ticketId: created.id, assigneeId: 'u-tech');
      expect(assigned.status, TicketStatus.assigned);
      expect(assigned.assigneeName, 'Karim Adel');

      expect((await repo.start(created.id)).status, TicketStatus.inProgress);
      await repo.addWorkLog(ticketId: created.id, note: 'Replaced the panel', minutes: 45);
      expect((await repo.resolve(created.id)).status, TicketStatus.resolved);

      final history = await repo.workLogsForAsset(asset.id);
      expect(history.first.note, 'Replaced the panel');
    });

    test('work logs punch months of the year', () async {
      final repo = DemoTicketsRepository(store, auth);
      final asset = store.assets.firstWhere((a) => store.logs.any((l) => l.assetId == a.id));
      final months = await repo.punchedMonths(assetIds: [asset.id], year: DateTime.now().year);
      expect(months[asset.id], isNotEmpty);
    });

    test('the live stream emits again when a ticket changes', () async {
      await auth.signIn(email: DemoStore.manager.email, password: 'secret1');
      final repo = DemoTicketsRepository(store, auth);
      final emissions = <int>[];
      final sub = repo.watchTickets().listen((t) => emissions.add(t.length));
      await Future<void>.delayed(Duration.zero);
      await repo.create(
        assetId: store.assets.first.id,
        title: 'Another problem',
        description: '',
        priority: TicketPriority.low,
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last, emissions.first + 1);
    });
  });
}
