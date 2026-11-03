import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'failures.dart';

/// Runs a Supabase call and turns every low-level error into one of our
/// [Failure]s, so cubits and screens only ever see failures they know.
Future<T> guardSupabase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Failure {
    rethrow;
  } on PostgrestException catch (e) {
    // 42501 = insufficient_privilege: a row-level-security policy said no.
    if (e.code == '42501') throw const PermissionFailure();
    throw ServerFailure(e.message);
  } on StorageException catch (e) {
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
