import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scandesk/core/errors/failures.dart';
import 'package:scandesk/features/auth/domain/app_user.dart';
import 'package:scandesk/features/auth/domain/auth_repository.dart';
import 'package:scandesk/features/auth/domain/user_role.dart';
import 'package:scandesk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:scandesk/features/auth/presentation/cubit/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  const user = AppUser(
    id: 'u1',
    email: 'tech@scandesk.app',
    fullName: 'Test Technician',
    role: UserRole.technician,
  );

  setUp(() => repository = MockAuthRepository());

  test('starts in AuthInitial', () {
    expect(AuthCubit(repository).state, const AuthInitial());
  });

  group('checkSession', () {
    blocTest<AuthCubit, AuthState>(
      'emits Authenticated when a session exists',
      setUp: () => when(() => repository.getCurrentUser())
          .thenAnswer((_) async => user),
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.checkSession(),
      expect: () => [const Authenticated(user)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits Unauthenticated when there is no session',
      setUp: () => when(() => repository.getCurrentUser())
          .thenAnswer((_) async => null),
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.checkSession(),
      expect: () => [const Unauthenticated()],
    );
  });

  group('signIn', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Authenticating, Authenticated] on success',
      setUp: () => when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user),
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.signIn(email: 'a@b.com', password: '123456'),
      expect: () => [const Authenticating(), const Authenticated(user)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Authenticating, AuthError] when the repository fails',
      setUp: () => when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure('Invalid login credentials')),
      build: () => AuthCubit(repository),
      act: (cubit) => cubit.signIn(email: 'a@b.com', password: 'wrong1'),
      expect: () => [
        const Authenticating(),
        const AuthError('Invalid login credentials'),
      ],
    );
  });

  blocTest<AuthCubit, AuthState>(
    'signOut emits Unauthenticated',
    setUp: () => when(() => repository.signOut()).thenAnswer((_) async {}),
    build: () => AuthCubit(repository),
    act: (cubit) => cubit.signOut(),
    expect: () => [const Unauthenticated()],
  );
}
