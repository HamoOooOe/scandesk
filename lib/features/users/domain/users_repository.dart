import '../../auth/domain/user_role.dart';
import 'user_profile.dart';

/// Contract for managing users. Every method throws a `Failure` on error.
abstract interface class UsersRepository {
  Future<List<UserProfile>> getUsers();

  /// Changes a user's role. Only managers are allowed (enforced by RLS);
  /// throws a `PermissionFailure` otherwise.
  Future<void> changeRole({required String userId, required UserRole role});
}
