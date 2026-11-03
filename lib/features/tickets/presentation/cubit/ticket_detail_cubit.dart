import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/ticket.dart';
import '../../domain/tickets_repository.dart';

class TicketDetailState extends Equatable {
  const TicketDetailState({
    this.loading = true,
    this.busy = false,
    this.ticket,
    this.logs = const [],
    this.staff = const [],
    this.error,
    this.notice,
  });

  final bool loading;

  /// An action (assign, start, resolve, log work) is in flight.
  final bool busy;
  final Ticket? ticket;
  final List<WorkLog> logs;
  final List<StaffMember> staff;
  final String? error;

  /// One-shot message for a snackbar ("Work logged").
  final String? notice;

  TicketDetailState copyWith({
    bool? loading,
    bool? busy,
    Ticket? ticket,
    List<WorkLog>? logs,
    List<StaffMember>? staff,
    String? error,
    String? notice,
  }) {
    return TicketDetailState(
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      ticket: ticket ?? this.ticket,
      logs: logs ?? this.logs,
      staff: staff ?? this.staff,
      error: error,
      notice: notice,
    );
  }

  @override
  List<Object?> get props => [loading, busy, ticket, logs, staff, error, notice];
}

/// One ticket, live. When anyone changes it, the screen updates and the
/// punch track moves to the new station.
class TicketDetailCubit extends Cubit<TicketDetailState> {
  TicketDetailCubit(this._repository) : super(const TicketDetailState());

  final TicketsRepository _repository;
  StreamSubscription<List<Ticket>>? _subscription;
  String _id = '';

  Future<void> load(String ticketId) async {
    _id = ticketId;
    try {
      final ticket = await _repository.getById(ticketId);
      final logs = await _repository.workLogsForTicket(ticketId);
      final staff = await _repository.technicians();
      emit(TicketDetailState(loading: false, ticket: ticket, logs: logs, staff: staff));
      _subscription?.cancel();
      _subscription = _repository.watchTickets().listen((all) async {
        final fresh = all.where((t) => t.id == _id).firstOrNull;
        if (fresh == null || fresh == state.ticket) return;
        final newLogs = await _repository.workLogsForTicket(_id);
        if (!isClosed) emit(state.copyWith(ticket: fresh, logs: newLogs));
      });
    } on Failure catch (failure) {
      emit(TicketDetailState(loading: false, error: failure.message));
    }
  }

  Future<void> assign(String assigneeId) =>
      _run(() => _repository.assign(ticketId: _id, assigneeId: assigneeId));

  Future<void> start() => _run(() => _repository.start(_id));

  Future<void> resolve() => _run(() => _repository.resolve(_id));

  Future<void> logWork({required String note, int minutes = 0, String parts = ''}) =>
      _run(
        () => _repository.addWorkLog(ticketId: _id, note: note, minutes: minutes, parts: parts),
        notice: 'logged',
      );

  Future<void> _run(Future<Object?> Function() action, {String? notice}) async {
    emit(state.copyWith(busy: true));
    try {
      await action();
      final ticket = await _repository.getById(_id);
      final logs = await _repository.workLogsForTicket(_id);
      emit(state.copyWith(busy: false, ticket: ticket, logs: logs, notice: notice));
    } on Failure catch (failure) {
      emit(state.copyWith(busy: false, error: failure.message));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
