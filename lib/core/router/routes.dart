import '../../features/auth/domain/user_role.dart';

/// Every route path in one place, so a typo can't break navigation.
class Routes {
  const Routes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // One home per role.
  static const String employeeHome = '/employee';
  static const String technicianHome = '/technician';
  static const String managerHome = '/manager';

  /// The home screen path for a role.
  static String homeFor(UserRole role) => switch (role) {
    UserRole.employee => employeeHome,
    UserRole.technician => technicianHome,
    UserRole.manager => managerHome,
  };

  /// Which role owns a path, or null if the path is not a role home.
  static UserRole? roleOwning(String location) {
    for (final role in UserRole.values) {
      final home = homeFor(role);
      if (location == home || location.startsWith('$home/')) return role;
    }
    return null;
  }
}
