import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import 'profile_model.dart';

/// Supabase implementation of [AuthRepository].
///
/// Needs the `profiles` table and its sign-up trigger from
/// `supabase/migrations/0001_create_profiles.sql`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<void> get onSignedOut => _client.auth.onAuthStateChange.where(
    (state) => state.event == AuthChangeEvent.signedOut,
  );

  @override
  Stream<void> get onPasswordRecovery => _client.auth.onAuthStateChange.where(
    (state) => state.event == AuthChangeEvent.passwordRecovery,
  );

  @override
  Future<void> updatePassword(String newPassword) {
    return _guard(
      () => _client.auth.updateUser(UserAttributes(password: newPassword)),
    );
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return _guard(() async {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      return _loadProfile(user);
    });
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _guard(() async {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) throw const AuthFailure();
      return _loadProfile(user);
    });
  }

  @override
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    // `full_name` is copied into `profiles` by the database trigger.
    return _guard(() async {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
    });
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _guard(
      () => _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppConstants.passwordResetRedirect,
      ),
    );
  }

  @override
  Future<void> signOut() => _guard(() => _client.auth.signOut());

  Future<AppUser> _loadProfile(User user) async {
    final row = await _client
        .from(AppConstants.profilesTable)
        .select()
        .eq('id', user.id)
        .single();
    return ProfileModel.fromJson(row).toEntity(email: user.email ?? '');
  }

  /// Converts Supabase and network exceptions into [Failure]s.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    } on SocketException {
      throw const NetworkFailure();
    } on ClientException {
      // The http package wraps socket errors (no internet, DNS) in this.
      throw const NetworkFailure();
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
