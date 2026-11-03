import 'package:flutter_test/flutter_test.dart';

import 'package:scandesk/features/auth/domain/user_role.dart';
import 'package:scandesk/features/tickets/domain/ticket.dart';
import 'package:scandesk/features/tickets/domain/ticket_rules.dart';

Ticket ticket(TicketStatus status, {String? assigneeId}) => Ticket(
  id: 't1',
  assetId: 'a1',
  assetCode: 'LAP-0001',
  assetName: 'Laptop',
  title: 'Broken',
  description: '',
  status: status,
  priority: TicketPriority.medium,
  reporterId: 'emp',
  reporterName: 'Emp',
  assigneeId: assigneeId,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('canMove', () {
    test('moves forward one step at a time', () {
      expect(TicketRules.canMove(TicketStatus.open, TicketStatus.assigned), isTrue);
      expect(TicketRules.canMove(TicketStatus.assigned, TicketStatus.inProgress), isTrue);
      expect(TicketRules.canMove(TicketStatus.inProgress, TicketStatus.resolved), isTrue);
    });

    test('never skips a step or goes back', () {
      expect(TicketRules.canMove(TicketStatus.open, TicketStatus.inProgress), isFalse);
      expect(TicketRules.canMove(TicketStatus.open, TicketStatus.resolved), isFalse);
      expect(TicketRules.canMove(TicketStatus.resolved, TicketStatus.open), isFalse);
      expect(TicketRules.canMove(TicketStatus.inProgress, TicketStatus.assigned), isFalse);
    });

    test('an assigned ticket can be re-assigned', () {
      expect(TicketRules.canMove(TicketStatus.assigned, TicketStatus.assigned), isTrue);
    });
  });

  group('who may act', () {
    test('only managers assign, and only before work starts', () {
      expect(TicketRules.canAssign(UserRole.manager, ticket(TicketStatus.open)), isTrue);
      expect(TicketRules.canAssign(UserRole.manager, ticket(TicketStatus.assigned)), isTrue);
      expect(TicketRules.canAssign(UserRole.manager, ticket(TicketStatus.inProgress)), isFalse);
      expect(TicketRules.canAssign(UserRole.technician, ticket(TicketStatus.open)), isFalse);
      expect(TicketRules.canAssign(UserRole.employee, ticket(TicketStatus.open)), isFalse);
    });

    test('the assignee starts work, another technician cannot', () {
      final t = ticket(TicketStatus.assigned, assigneeId: 'tech1');
      expect(TicketRules.canStart(UserRole.technician, 'tech1', t), isTrue);
      expect(TicketRules.canStart(UserRole.technician, 'tech2', t), isFalse);
      expect(TicketRules.canStart(UserRole.manager, 'boss', t), isTrue);
      expect(TicketRules.canStart(UserRole.employee, 'emp', t), isFalse);
    });

    test('resolve needs work in progress', () {
      final working = ticket(TicketStatus.inProgress, assigneeId: 'tech1');
      expect(TicketRules.canResolve(UserRole.technician, 'tech1', working), isTrue);
      expect(
        TicketRules.canResolve(UserRole.technician, 'tech1', ticket(TicketStatus.assigned, assigneeId: 'tech1')),
        isFalse,
      );
    });

    test('work can be logged until the ticket is resolved', () {
      expect(
        TicketRules.canLogWork(UserRole.technician, 'tech1', ticket(TicketStatus.inProgress, assigneeId: 'tech1')),
        isTrue,
      );
      expect(
        TicketRules.canLogWork(UserRole.technician, 'tech1', ticket(TicketStatus.resolved, assigneeId: 'tech1')),
        isFalse,
      );
      expect(TicketRules.canLogWork(UserRole.technician, 'tech1', ticket(TicketStatus.open)), isFalse);
    });
  });
}
