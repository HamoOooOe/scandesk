import 'package:equatable/equatable.dart';

/// Where a ticket is. A ticket only ever moves forward, one step at a
/// time. Stored as `open`, `assigned`, `in_progress`, `resolved`.
enum TicketStatus {
  open('open'),
  assigned('assigned'),
  inProgress('in_progress'),
  resolved('resolved');

  const TicketStatus(this.value);
  final String value;

  /// Station on the punch track (0 to 3).
  int get stage => index;

  TicketStatus? get next =>
      index + 1 < TicketStatus.values.length ? TicketStatus.values[index + 1] : null;

  static TicketStatus fromValue(String? value) => TicketStatus.values
      .firstWhere((s) => s.value == value, orElse: () => TicketStatus.open);
}

enum TicketPriority {
  low,
  medium,
  high;

  static TicketPriority fromValue(String? value) => TicketPriority.values
      .firstWhere((p) => p.name == value, orElse: () => TicketPriority.medium);
}

/// A problem report about one asset. Pure Dart.
class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeId,
    this.assigneeName,
    this.photoUrls = const [],
  });

  final String id;
  final String assetId;
  final String assetCode;
  final String assetName;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final String reporterId;
  final String reporterName;
  final String? assigneeId;
  final String? assigneeName;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Network URLs, or local file paths for photos not uploaded yet.
  final List<String> photoUrls;

  bool get isClosed => status == TicketStatus.resolved;

  Ticket copyWith({
    TicketStatus? status,
    String? assigneeId,
    String? assigneeName,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id,
      assetId: assetId,
      assetCode: assetCode,
      assetName: assetName,
      title: title,
      description: description,
      status: status ?? this.status,
      priority: priority,
      reporterId: reporterId,
      reporterName: reporterName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      photoUrls: photoUrls,
    );
  }

  @override
  List<Object?> get props => [
    id, assetId, assetCode, assetName, title, description, status, priority,
    reporterId, reporterName, assigneeId, assigneeName, createdAt, updatedAt,
    photoUrls,
  ];
}

/// What a technician did on a ticket. These rows are the repair history
/// of an asset and the source of its punched months.
class WorkLog extends Equatable {
  const WorkLog({
    required this.id,
    required this.ticketId,
    required this.assetId,
    required this.authorName,
    required this.note,
    required this.createdAt,
    this.minutes = 0,
    this.parts = '',
  });

  final String id;
  final String ticketId;
  final String assetId;
  final String authorName;
  final String note;
  final int minutes;
  final String parts;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, ticketId, assetId, authorName, note, minutes, parts, createdAt];
}

/// A technician a manager can assign a ticket to.
class StaffMember extends Equatable {
  const StaffMember({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
