import 'dart:async';

import '../../features/assets/domain/asset.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/domain/user_role.dart';
import '../../features/tickets/domain/ticket.dart';
import '../../features/users/domain/user_profile.dart';

/// Synthetic data for demo mode (`--dart-define=DEMO=true`).
///
/// Everything here is made up: names, devices, serial numbers and
/// tickets. It exists so the app can be shown and tested without a
/// backend. The real app reads the same shapes from Supabase.
class DemoStore {
  DemoStore() {
    _seed();
  }

  static const employee = AppUser(
    id: 'u-employee',
    email: 'employee@demo.scandesk',
    fullName: 'Mariam Hassan',
    role: UserRole.employee,
  );
  static const technician = AppUser(
    id: 'u-tech',
    email: 'technician@demo.scandesk',
    fullName: 'Karim Adel',
    role: UserRole.technician,
  );
  static const manager = AppUser(
    id: 'u-manager',
    email: 'manager@demo.scandesk',
    fullName: 'Hana Samir',
    role: UserRole.manager,
  );

  final List<Site> sites = [];
  final List<Location> locations = [];
  final List<Asset> assets = [];
  final List<Ticket> tickets = [];
  final List<WorkLog> logs = [];

  final List<StaffMember> staff = const [
    StaffMember(id: 'u-tech', name: 'Karim Adel'),
    StaffMember(id: 'u-tech2', name: 'Omar Fathy'),
    StaffMember(id: 'u-tech3', name: 'Salma Nabil'),
  ];

  late final List<UserProfile> profiles = [
    UserProfile(id: employee.id, fullName: employee.fullName, role: UserRole.employee),
    const UserProfile(id: 'u-emp2', fullName: 'Ahmed Tarek', role: UserRole.employee),
    const UserProfile(id: 'u-emp3', fullName: 'Dina Ali', role: UserRole.employee),
    UserProfile(id: technician.id, fullName: technician.fullName, role: UserRole.technician),
    const UserProfile(id: 'u-tech2', fullName: 'Omar Fathy', role: UserRole.technician),
    const UserProfile(id: 'u-tech3', fullName: 'Salma Nabil', role: UserRole.technician),
    UserProfile(id: manager.id, fullName: manager.fullName, role: UserRole.manager),
  ];

  final StreamController<void> _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;
  void notifyChanged() => _changes.add(null);

  final Map<AssetCategory, int> _codeCounters = {};
  int _ids = 1000;
  String newId(String prefix) => '$prefix-${_ids++}';

  /// `LAP-0007`: category prefix plus the next number for that prefix.
  String nextCode(AssetCategory category) {
    final next = (_codeCounters[category] ?? 0) + 1;
    _codeCounters[category] = next;
    return '${category.codePrefix}-${next.toString().padLeft(4, '0')}';
  }

  void _seed() {
    final now = DateTime.now();

    sites.addAll(const [
      Site(id: 's-cairo', name: 'Cairo HQ', city: 'Cairo'),
      Site(id: 's-alex', name: 'Alexandria Branch', city: 'Alexandria'),
    ]);
    locations.addAll(const [
      Location(id: 'l-open', siteId: 's-cairo', name: 'Floor 1 · Open office'),
      Location(id: 'l-fin', siteId: 's-cairo', name: 'Floor 2 · Finance'),
      Location(id: 'l-srv', siteId: 's-cairo', name: 'Server room'),
      Location(id: 'l-rec', siteId: 's-cairo', name: 'Reception'),
      Location(id: 'l-meet', siteId: 's-cairo', name: 'Meeting room A'),
      Location(id: 'l-branch', siteId: 's-alex', name: 'Branch office'),
      Location(id: 'l-store', siteId: 's-alex', name: 'Stock room'),
    ]);

    const templates = <(AssetCategory, String, String)>[
      (AssetCategory.laptop, 'Dell', 'Latitude 5440'),
      (AssetCategory.laptop, 'Lenovo', 'ThinkPad T14 Gen 4'),
      (AssetCategory.laptop, 'HP', 'EliteBook 840 G10'),
      (AssetCategory.laptop, 'Apple', 'MacBook Air M2'),
      (AssetCategory.desktop, 'HP', 'ProDesk 400 G9'),
      (AssetCategory.desktop, 'Dell', 'OptiPlex 7010'),
      (AssetCategory.monitor, 'Dell', 'U2723QE'),
      (AssetCategory.monitor, 'LG', '27UP850'),
      (AssetCategory.printer, 'HP', 'LaserJet Pro M404dn'),
      (AssetCategory.printer, 'Canon', 'imageRUNNER 2625i'),
      (AssetCategory.printer, 'Epson', 'EcoTank L3250'),
      (AssetCategory.phone, 'Apple', 'iPhone 13'),
      (AssetCategory.phone, 'Samsung', 'Galaxy S23'),
      (AssetCategory.network, 'Cisco', 'Catalyst 2960-X'),
      (AssetCategory.network, 'Ubiquiti', 'UniFi U6 Pro'),
      (AssetCategory.network, 'MikroTik', 'hAP ax3'),
    ];
    const people = ['Mariam Hassan', 'Ahmed Tarek', 'Dina Ali', 'Youssef Nour', 'Nada Khaled', 'Tamer Ezzat', 'Laila Magdy', ''];
    const places = ['l-open', 'l-fin', 'l-srv', 'l-rec', 'l-meet', 'l-branch', 'l-store'];

    for (var i = 0; i < 38; i++) {
      final t = templates[(i * 5) % templates.length];
      final place = places[(i * 3) % places.length];
      final site = locations.firstWhere((l) => l.id == place).siteId;
      final isInfra = t.$1 == AssetCategory.network || t.$1 == AssetCategory.printer;
      final status = i % 13 == 5
          ? AssetStatus.inRepair
          : i % 17 == 9
          ? AssetStatus.storage
          : i == 30
          ? AssetStatus.retired
          : AssetStatus.active;
      final purchase = DateTime(now.year - 1 - (i % 3), 1 + (i * 7) % 12, 5 + i % 20);
      assets.add(
        Asset(
          id: 'a-${i + 1}',
          code: nextCode(t.$1),
          name: '${t.$2} ${t.$3}',
          category: t.$1,
          status: status,
          brand: t.$2,
          model: t.$3,
          serial: 'SN${(7340000 + i * 8731).toString()}',
          siteId: site,
          locationId: place,
          assignedTo: isInfra ? '' : people[i % people.length],
          purchaseDate: purchase,
          warrantyUntil: purchase.add(const Duration(days: 365 * 3)),
          notes: '',
        ),
      );
    }

    // History: resolved tickets with a work log each. They are what
    // punches the months on the ring.
    const notes = <AssetCategory, List<String>>{
      AssetCategory.laptop: ['Replaced the battery', 'Cleaned fans and re-pasted the CPU', 'Reinstalled the OS and drivers', 'Replaced a cracked keyboard'],
      AssetCategory.desktop: ['Upgraded RAM to 16 GB', 'Replaced the power supply', 'Cloned the disk to a new SSD'],
      AssetCategory.monitor: ['Replaced the DisplayPort cable', 'Recalibrated colors', 'Replaced the stand'],
      AssetCategory.printer: ['Replaced the toner cartridge', 'Cleared a paper jam and replaced rollers', 'Replaced the fuser unit', 'Updated the firmware'],
      AssetCategory.phone: ['Replaced the screen', 'Restored from backup after a reset'],
      AssetCategory.network: ['Updated the firmware', 'Re-crimped the uplink cable', 'Replaced a failed SFP module'],
      AssetCategory.other: ['General check'],
    };
    const authors = ['Karim Adel', 'Omar Fathy', 'Salma Nabil'];
    var h = 0;
    for (var i = 0; i < assets.length; i++) {
      if (i % 4 == 3) continue; // a quarter of devices were never serviced
      final a = assets[i];
      final count = 1 + (i % 4);
      for (var k = 0; k < count; k++) {
        final month = ((i * 3 + k * 4) % 10) + 1;
        final when = DateTime(now.year, month, 3 + (i + k * 5) % 22, 9 + k);
        if (when.isAfter(now)) continue;
        final pool = notes[a.category]!;
        final id = 'th-${h++}';
        final author = authors[(i + k) % authors.length];
        tickets.add(
          Ticket(
            id: id,
            assetId: a.id,
            assetCode: a.code,
            assetName: a.name,
            title: pool[(i + k) % pool.length],
            description: '',
            status: TicketStatus.resolved,
            priority: TicketPriority.low,
            reporterId: 'u-emp2',
            reporterName: 'Ahmed Tarek',
            assigneeId: 'u-tech',
            assigneeName: author,
            createdAt: when.subtract(const Duration(days: 1)),
            updatedAt: when,
          ),
        );
        logs.add(
          WorkLog(
            id: 'wl-$id',
            ticketId: id,
            assetId: a.id,
            authorName: author,
            note: pool[(i + k) % pool.length],
            minutes: 20 + (i * 7 + k * 13) % 70,
            parts: k.isEven ? '' : 'Spare part from stock',
            createdAt: when,
          ),
        );
      }
    }

    Asset byCode(String code) => assets.firstWhere((a) => a.code == code);
    Ticket live({
      required String id,
      required Asset asset,
      required String title,
      required String description,
      required TicketStatus status,
      required TicketPriority priority,
      required Duration age,
      Duration? since,
      String reporterId = 'u-emp2',
      String reporterName = 'Ahmed Tarek',
      StaffMember? assignee,
    }) {
      return Ticket(
        id: id,
        assetId: asset.id,
        assetCode: asset.code,
        assetName: asset.name,
        title: title,
        description: description,
        status: status,
        priority: priority,
        reporterId: reporterId,
        reporterName: reporterName,
        assigneeId: assignee?.id,
        assigneeName: assignee?.name,
        createdAt: now.subtract(age),
        updatedAt: now.subtract(since ?? age),
      );
    }

    final karim = staff[0];
    final omar = staff[1];
    final salma = staff[2];
    tickets.addAll([
      live(
        id: 't-1', asset: byCode('LAP-0003'), title: 'Laptop will not boot after the update',
        description: 'Black screen after the Windows update last night. The power light is on but nothing shows.',
        status: TicketStatus.inProgress, priority: TicketPriority.high,
        age: const Duration(hours: 5), since: const Duration(minutes: 40),
        reporterId: 'u-employee', reporterName: 'Mariam Hassan', assignee: karim,
      ),
      live(
        id: 't-2', asset: byCode('PRT-0004'), title: 'Printer jams on every second page',
        description: 'Paper gets stuck near the back roller. Cleared it twice already.',
        status: TicketStatus.assigned, priority: TicketPriority.medium,
        age: const Duration(hours: 9), since: const Duration(hours: 2),
        reporterId: 'u-employee', reporterName: 'Mariam Hassan', assignee: karim,
      ),
      live(
        id: 't-3', asset: byCode('NET-0002'), title: 'Wi-Fi drops every few minutes in meeting room A',
        description: 'Video calls disconnect. It started after the power cut on Sunday.',
        status: TicketStatus.open, priority: TicketPriority.high,
        age: const Duration(minutes: 35),
      ),
      live(
        id: 't-4', asset: byCode('MON-0002'), title: 'Screen flickers when the cable moves',
        description: 'Flickers and goes black for a second.',
        status: TicketStatus.open, priority: TicketPriority.low,
        age: const Duration(hours: 3), reporterId: 'u-emp3', reporterName: 'Dina Ali',
      ),
      live(
        id: 't-5', asset: byCode('LAP-0007'), title: 'Battery drains in under an hour',
        description: 'It was fine last month. Now it dies at 60% sometimes.',
        status: TicketStatus.assigned, priority: TicketPriority.medium,
        age: const Duration(days: 1, hours: 2), since: const Duration(hours: 20),
        reporterId: 'u-employee', reporterName: 'Mariam Hassan', assignee: omar,
      ),
      live(
        id: 't-6', asset: byCode('PHN-0001'), title: 'Cannot receive work email on the phone',
        description: 'Mail app asks for the password again and again.',
        status: TicketStatus.inProgress, priority: TicketPriority.medium,
        age: const Duration(days: 1, hours: 8), since: const Duration(hours: 3),
        reporterId: 'u-emp3', reporterName: 'Dina Ali', assignee: salma,
      ),
      live(
        id: 't-7', asset: byCode('DSK-0003'), title: 'Computer restarts by itself',
        description: 'Restarts without warning, mostly in the afternoon.',
        status: TicketStatus.open, priority: TicketPriority.high,
        age: const Duration(hours: 1, minutes: 10),
        reporterId: 'u-employee', reporterName: 'Mariam Hassan',
      ),
      live(
        id: 't-8', asset: byCode('PRT-0001'), title: 'Toner low warning will not clear',
        description: 'Replaced the toner but the warning is still there.',
        status: TicketStatus.resolved, priority: TicketPriority.low,
        age: const Duration(days: 2), since: const Duration(days: 1, hours: 4),
        reporterId: 'u-employee', reporterName: 'Mariam Hassan', assignee: karim,
      ),
      live(
        id: 't-9', asset: byCode('NET-0001'), title: 'Switch port 14 is dead',
        description: 'Nothing connected to port 14 gets a link.',
        status: TicketStatus.inProgress, priority: TicketPriority.high,
        age: const Duration(days: 2, hours: 3), since: const Duration(hours: 6),
        assignee: karim,
      ),
      live(
        id: 't-10', asset: byCode('LAP-0009'), title: 'Keyboard types the wrong characters',
        description: 'Some keys type numbers instead of letters.',
        status: TicketStatus.assigned, priority: TicketPriority.low,
        age: const Duration(days: 3), since: const Duration(days: 2, hours: 10),
        reporterId: 'u-emp3', reporterName: 'Dina Ali', assignee: salma,
      ),
      live(
        id: 't-11', asset: byCode('MON-0001'), title: 'No signal from the docking station',
        description: 'Laptop works, monitor says no signal.',
        status: TicketStatus.resolved, priority: TicketPriority.medium,
        age: const Duration(days: 4), since: const Duration(days: 3, hours: 2), assignee: omar,
      ),
      live(
        id: 't-12', asset: byCode('PRT-0006'), title: 'Prints with a grey stripe',
        description: 'A vertical grey stripe on every page.',
        status: TicketStatus.open, priority: TicketPriority.medium,
        age: const Duration(hours: 22), reporterId: 'u-emp3', reporterName: 'Dina Ali',
      ),
    ]);

    // Live tickets get matching work logs where work has started.
    logs.addAll([
      WorkLog(
        id: 'wl-t-1', ticketId: 't-1', assetId: byCode('LAP-0003').id, authorName: 'Karim Adel',
        note: 'Booted into recovery. Rolling back the update and checking the disk.',
        minutes: 35, createdAt: now.subtract(const Duration(minutes: 40)),
      ),
      WorkLog(
        id: 'wl-t-8', ticketId: 't-8', assetId: byCode('PRT-0001').id, authorName: 'Karim Adel',
        note: 'Reset the toner counter from the service menu.',
        minutes: 15, createdAt: now.subtract(const Duration(days: 1, hours: 4)),
      ),
      WorkLog(
        id: 'wl-t-9', ticketId: 't-9', assetId: byCode('NET-0001').id, authorName: 'Karim Adel',
        note: 'Tested port 14 with a cable tester. The port itself is dead, moving the uplink to port 22.',
        minutes: 50, createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ]);
  }
}
