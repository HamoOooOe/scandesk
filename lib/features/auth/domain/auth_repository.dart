import 'app_user.dart';

/// The contract for authentication. The presentation layer only knows
/// this interface, so it can be tested with a fake and the backend can
/// change without touching any screen.
///
/// Every method throws a `Failure` (core/errors/failures.dart) on error.
abstract interface class AuthRepository {
  /// The user from the saved session, or null if nobody is logged in.
  Future<AppUser?> getCurrentUser();

  Future<AppUser> signIn({required String email, required String password});

  /// Sprint 1: used by the register page.
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
