import 'package:equatable/equatable.dart';

import '../../domain/user_profile.dart';

enum UsersStatus { loading, loaded, error }

/// One state class: the list stays on screen while a role change runs or
/// fails, and [errorMessage] is only set when something went wrong.
class UsersState extends Equatable {
  const UsersState({
    this.status = UsersStatus.loading,
    this.users = const [],
    this.errorMessage,
  });

  final UsersStatus status;
  final List<UserProfile> users;
  final String? errorMessage;

  UsersState copyWith({
    UsersStatus? status,
    List<UserProfile>? users,
    String? errorMessage,
  }) => UsersState(
    status: status ?? this.status,
    users: users ?? this.users,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, users, errorMessage];
}
