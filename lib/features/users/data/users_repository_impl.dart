import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../auth/domain/user_role.dart';
import '../domain/user_profile.dart';
import '../domain/users_repository.dart';

/// Supabase implementation of [UsersRepository]. Reads and updates the
/// `profiles` table; the RLS policies decide who is allowed to do what.
class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<UserProfile>> getUsers() {
    return _guard(() async {
      final rows = await _client
          .from(AppConstants.profilesTable)
          .select('id, full_name, role')
          .order('full_name');
      return rows
          .map(
            (row) => UserProfile(
              id: row['id'] as String,
              fullName: (row['full_name'] as String?) ?? '',
              role: UserRole.fromValue(row['role'] as String?),
            ),
          )
          .toList();
    });
  }

  @override
  Future<void> changeRole({required String userId, required UserRole role}) {
    return _guard(() async {
      final updated = await _client
          .from(AppConstants.profilesTable)
          .update({'role': role.name})
          .eq('id', userId)
          .select('id');
      // RLS does not raise an error for a blocked update, it just matches
      // zero rows. So an empty result means "not allowed".
      if (updated.isEmpty) throw const PermissionFailure();
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerFailure(e.message);
    } on SocketException {
      throw const NetworkFailure();
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
