/// The three kinds of ScanDesk users. Stored as text in `profiles.role`.
enum UserRole {
  employee,
  technician,
  manager;

  /// Turns the database value into a role. Unknown values become
  /// [UserRole.employee], the role with the least permissions.
  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.employee,
    );
  }

  bool get canManageAssets => this == UserRole.manager;
  bool get canAssignTickets => this == UserRole.manager;
  bool get canWorkOnTickets =>
      this == UserRole.technician || this == UserRole.manager;
}
