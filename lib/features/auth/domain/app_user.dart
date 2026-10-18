import 'package:equatable/equatable.dart';

import 'user_role.dart';

/// The logged-in user as the rest of the app sees it.
/// Pure Dart: no Supabase, no Flutter imports in the domain layer.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.siteId,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? siteId;

  @override
  List<Object?> get props => [id, email, fullName, role, siteId];
}
