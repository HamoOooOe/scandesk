import '../../auth/domain/user_role.dart';
import 'ticket.dart';

/// Who may move a ticket where. Pure functions, so they are easy to test
/// and the same rules can be repeated in the database (see the SQL
/// migration for tickets).
class TicketRules {
  const TicketRules._();

  /// A ticket moves forward one step at a time. Re-assigning an
  /// already assigned ticket is allowed (it stays "assigned").
  static bool canMove(TicketStatus from, TicketStatus to) {
    if (from == TicketStatus.assigned && to == TicketStatus.assigned) return true;
    return to.index == from.index + 1;
  }

  /// Only managers assign tickets, and only before work has started.
  static bool canAssign(UserRole role, Ticket ticket) =>
      role.canAssignTickets &&
      (ticket.status == TicketStatus.open || ticket.status == TicketStatus.assigned);

  /// The assigned technician starts work (a manager may too).
  static bool canStart(UserRole role, String userId, Ticket ticket) {
    if (ticket.status != TicketStatus.assigned) return false;
    return role == UserRole.manager ||
        (role == UserRole.technician && ticket.assigneeId == userId);
  }

  static bool canResolve(UserRole role, String userId, Ticket ticket) {
    if (ticket.status != TicketStatus.inProgress) return false;
    return role == UserRole.manager ||
        (role == UserRole.technician && ticket.assigneeId == userId);
  }

  /// Work can be logged while the ticket is assigned or in progress.
  static bool canLogWork(UserRole role, String userId, Ticket ticket) {
    if (ticket.isClosed || ticket.status == TicketStatus.open) return false;
    return role == UserRole.manager ||
        (role == UserRole.technician && ticket.assigneeId == userId);
  }
}
