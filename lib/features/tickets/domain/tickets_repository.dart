import 'ticket.dart';

/// Contract for tickets and work logs. Every method throws a `Failure`
/// on error. Who is acting is decided by the backend session (Supabase
/// uses `auth.uid()`), not passed in.
abstract interface class TicketsRepository {
  /// Live list of the tickets the current user may see (employees see
  /// their own, technicians and managers see everything). Emits again
  /// whenever a ticket changes.
  Stream<List<Ticket>> watchTickets();

  Future<Ticket?> getById(String id);

  Future<Ticket> create({
    required String assetId,
    required String title,
    required String description,
    required TicketPriority priority,
    List<String> photoPaths = const [],
  });

  Future<Ticket> assign({required String ticketId, required String assigneeId});
  Future<Ticket> start(String ticketId);
  Future<Ticket> resolve(String ticketId);

  Future<WorkLog> addWorkLog({
    required String ticketId,
    required String note,
    int minutes = 0,
    String parts = '',
  });

  Future<List<WorkLog>> workLogsForTicket(String ticketId);

  /// The repair history of one asset, newest first.
  Future<List<WorkLog>> workLogsForAsset(String assetId);

  Future<List<StaffMember>> technicians();

  /// For each asset, the months (1 to 12) of [year] that have a work log.
  /// One call for a whole page of assets, so the list never does N queries.
  Future<Map<String, Set<int>>> punchedMonths({
    required Iterable<String> assetIds,
    required int year,
  });
}
