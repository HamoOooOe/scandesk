import 'package:equatable/equatable.dart';

import '../../auth/domain/user_role.dart';

/// One row of the users list shown to managers. Pure Dart.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final UserRole role;

  UserProfile copyWith({UserRole? role}) =>
      UserProfile(id: id, fullName: fullName, role: role ?? this.role);

  @override
  List<Object?> get props => [id, fullName, role];
}
