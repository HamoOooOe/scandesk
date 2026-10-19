import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scandesk/core/errors/failures.dart';
import 'package:scandesk/features/auth/data/auth_repository_impl.dart';
import 'package:scandesk/features/auth/domain/app_user.dart';
import 'package:scandesk/features/auth/domain/user_role.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockUser extends Mock implements User {}

/// Stands in for the `.select().eq().single()` chain: it is awaitable and
/// completes with one profile row, like the real builder.
class FakeProfileQuery extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>> {
  FakeProfileQuery(this.row);

  final Map<String, dynamic> row;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(Map<String, dynamic> value) onValue, {
    Function? onError,
  }) => Future.value(row).then(onValue, onError: onError);
}

class FakeFilter extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  FakeFilter(this.row);

  final Map<String, dynamic> row;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) => this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() =>
      FakeProfileQuery(row);
}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late AuthRepositoryImpl repository;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    repository = AuthRepositoryImpl(client);
  });

  /// Makes `client.from('profiles').select().eq().single()` return [row].
  void stubProfile(Map<String, dynamic> row) {
    final builder = MockQueryBuilder();
    when(() => client.from('profiles')).thenAnswer((_) => builder);
    when(() => builder.select()).thenAnswer((_) => FakeFilter(row));
  }

  User supabaseUser({String id = 'u1', String email = 'a@b.com'}) {
    final user = MockUser();
    when(() => user.id).thenReturn(id);
    when(() => user.email).thenReturn(email);
    return user;
  }

  group('getCurrentUser', () {
    test('returns null when nobody is logged in', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(await repository.getCurrentUser(), isNull);
    });

    test('returns the user with their role from the profile', () async {
      final user = supabaseUser();
      when(() => auth.currentUser).thenReturn(user);
      stubProfile({'id': 'u1', 'full_name': 'Sara', 'role': 'technician'});

      final result = await repository.getCurrentUser();

      expect(
        result,
        const AppUser(
          id: 'u1',
          email: 'a@b.com',
          fullName: 'Sara',
          role: UserRole.technician,
        ),
      );
    });
  });

  group('signIn', () {
    test('returns the user on success', () async {
      final user = supabaseUser();
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse(user: user));
      stubProfile({'id': 'u1', 'full_name': 'Sara', 'role': 'manager'});

      final result = await repository.signIn(
        email: ' a@b.com ',
        password: '123456',
      );

      expect(result.role, UserRole.manager);
      verify(
        () => auth.signInWithPassword(email: 'a@b.com', password: '123456'),
      ).called(1);
    });

    test('throws AuthFailure when Supabase rejects the login', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => repository.signIn(email: 'a@b.com', password: 'wrong1'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('throws AuthFailure when no user comes back', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse());

      expect(
        () => repository.signIn(email: 'a@b.com', password: '123456'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('throws NetworkFailure when there is no internet', () async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const SocketException('offline'));

      expect(
        () => repository.signIn(email: 'a@b.com', password: '123456'),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });

  test('maps an http ClientException (DNS/offline) to NetworkFailure', () {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(ClientException('Failed host lookup'));

    expect(
      () => repository.signIn(email: 'a@b.com', password: '123456'),
      throwsA(isA<NetworkFailure>()),
    );
  });

  group('signUp', () {
    test('sends the trimmed full name as metadata', () async {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => AuthResponse());

      await repository.signUp(
        fullName: '  Sara Ali ',
        email: 'a@b.com',
        password: '123456',
      );

      verify(
        () => auth.signUp(
          email: 'a@b.com',
          password: '123456',
          data: {'full_name': 'Sara Ali'},
        ),
      ).called(1);
    });

    test('maps an AuthException to AuthFailure', () async {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenThrow(const AuthException('User already registered'));

      expect(
        () => repository.signUp(
          fullName: 'Sara',
          email: 'a@b.com',
          password: '123456',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.message,
            'message',
            'User already registered',
          ),
        ),
      );
    });
  });

  group('signOut', () {
    test('calls Supabase signOut', () async {
      when(() => auth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => auth.signOut()).called(1);
    });

    test('maps errors to a Failure', () async {
      when(() => auth.signOut()).thenThrow(const AuthException('boom'));

      expect(() => repository.signOut(), throwsA(isA<AuthFailure>()));
    });
  });

  group('sendPasswordReset', () {
    test('asks Supabase to send the reset email', () async {
      when(() => auth.resetPasswordForEmail(any())).thenAnswer((_) async {});

      await repository.sendPasswordReset(' a@b.com ');

      verify(() => auth.resetPasswordForEmail('a@b.com')).called(1);
    });
  });
}
