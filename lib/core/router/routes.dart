import '../../features/auth/domain/user_role.dart';

/// Every route path in one place, so a typo can't break navigation.
class Routes {
  const Routes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // One home per role.
  static const String employeeHome = '/employee';
  static const String technicianHome = '/technician';
  static const String managerHome = '/manager';

  /// Manager-only. It sits under /manager, so the role guard in the
  /// router keeps everyone else out.
  static const String manageUsers = '/manager/users';

  // Shared screens (any signed-in user).
  static const String scan = '/scan';
  static String assetPath(String id) => '/asset/$id';
  static String assetQrPath(String id) => '/asset/$id/qr';
  static String reportPath(String assetId) => '/report/$assetId';
  static String ticketPath(String id) => '/ticket/$id';

  // Manager-only screens (see [managerOnly]).
  static const String assetNew = '/assets/new';
  static String assetEditPath(String id) => '/assets/$id/edit';
  static const String sites = '/sites';
  static const String labelSheet = '/labels';

  /// Paths only a manager may open, besides /manager itself.
  static bool managerOnly(String location) =>
      location == assetNew ||
      location.startsWith('/assets/') ||
      location == sites ||
      location == labelSheet;

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
