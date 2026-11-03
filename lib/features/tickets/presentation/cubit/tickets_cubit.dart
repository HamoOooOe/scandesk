import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/ticket.dart';
import '../../domain/tickets_repository.dart';

enum TicketFilter { active, mine, unassigned, resolved, all }

/// Remembers which tickets the user has opened, so a ticket that changed
/// since then stays lit in the list until it is opened. In memory only.
class SeenTickets {
  final Set<String> _opened = {};

  void markOpened(String ticketId) => _opened.add(ticketId);

  /// "Changed since you looked": it was updated after it was created,
  /// within the last three hours, and this user has not opened it yet.
  bool isFlagged(Ticket ticket, {DateTime? now}) {
    if (_opened.contains(ticket.id) || ticket.isClosed) return false;
    final current = now ?? DateTime.now();
    final changed = ticket.updatedAt.isAfter(ticket.createdAt.add(const Duration(minutes: 1)));
    return changed && current.difference(ticket.updatedAt) < const Duration(hours: 3);
  }
}

class TicketsState extends Equatable {
  const TicketsState({
    this.loading = true,
    this.tickets = const [],
    this.filter = TicketFilter.active,
    this.error,
  });

  final bool loading;
  final List<Ticket> tickets;
  final TicketFilter filter;
  final String? error;

  List<Ticket> visibleFor(String userId) {
    return tickets.where((t) {
      return switch (filter) {
        TicketFilter.active => !t.isClosed,
        TicketFilter.mine => !t.isClosed && t.assigneeId == userId,
        TicketFilter.unassigned => t.status == TicketStatus.open,
        TicketFilter.resolved => t.isClosed,
        TicketFilter.all => true,
      };
    }).toList();
  }

  TicketsState copyWith({bool? loading, List<Ticket>? tickets, TicketFilter? filter, String? error}) {
    return TicketsState(
      loading: loading ?? this.loading,
      tickets: tickets ?? this.tickets,
      filter: filter ?? this.filter,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, tickets, filter, error];
}

/// The live ticket list. It listens to the repository stream, so a
/// ticket that changes anywhere changes here without a refresh.
class TicketsCubit extends Cubit<TicketsState> {
  TicketsCubit(this._repository, this.seen, {TicketFilter initial = TicketFilter.active})
    : super(TicketsState(filter: initial));

  final TicketsRepository _repository;
  final SeenTickets seen;
  StreamSubscription<List<Ticket>>? _subscription;

  void start() {
    _subscription?.cancel();
    _subscription = _repository.watchTickets().listen(
      (tickets) => emit(state.copyWith(loading: false, tickets: tickets)),
      onError: (Object error) => emit(
        state.copyWith(
          loading: false,
          error: error is Failure ? error.message : const UnknownFailure().message,
        ),
      ),
    );
  }

  void setFilter(TicketFilter filter) => emit(state.copyWith(filter: filter));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
