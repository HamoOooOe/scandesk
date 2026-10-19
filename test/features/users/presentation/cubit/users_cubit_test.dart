import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:scandesk/core/errors/failures.dart';
import 'package:scandesk/features/auth/domain/user_role.dart';
import 'package:scandesk/features/users/domain/user_profile.dart';
import 'package:scandesk/features/users/domain/users_repository.dart';
import 'package:scandesk/features/users/presentation/cubit/users_cubit.dart';
import 'package:scandesk/features/users/presentation/cubit/users_state.dart';

class MockUsersRepository extends Mock implements UsersRepository {}

void main() {
  late MockUsersRepository repository;

  const ana = UserProfile(id: '1', fullName: 'Ana', role: UserRole.employee);
  const omar = UserProfile(id: '2', fullName: 'Omar', role: UserRole.manager);

  setUpAll(() => registerFallbackValue(UserRole.employee));

  setUp(() => repository = MockUsersRepository());

  group('load', () {
    blocTest<UsersCubit, UsersState>(
      'emits loaded users',
      setUp: () =>
          when(() => repository.getUsers())
              .thenAnswer((_) async => [ana, omar]),
      build: () => UsersCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        const UsersState(),
        const UsersState(status: UsersStatus.loaded, users: [ana, omar]),
      ],
    );

    blocTest<UsersCubit, UsersState>(
      'emits error when loading fails',
      setUp: () =>
          when(() => repository.getUsers()).thenThrow(const NetworkFailure()),
      build: () => UsersCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        const UsersState(),
        const UsersState(
          status: UsersStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('changeRole', () {
    blocTest<UsersCubit, UsersState>(
      'updates the role in the list',
      setUp: () => when(
        () => repository.changeRole(
          userId: any(named: 'userId'),
          role: any(named: 'role'),
        ),
      ).thenAnswer((_) async {}),
      build: () => UsersCubit(repository),
      seed: () =>
          const UsersState(status: UsersStatus.loaded, users: [ana, omar]),
      act: (cubit) => cubit.changeRole('1', UserRole.technician),
      expect: () => [
        UsersState(
          status: UsersStatus.loaded,
          users: [
            ana.copyWith(role: UserRole.technician),
            omar,
          ],
        ),
      ],
    );

    blocTest<UsersCubit, UsersState>(
      'keeps the list and reports an error when not allowed',
      setUp: () => when(
        () => repository.changeRole(
          userId: any(named: 'userId'),
          role: any(named: 'role'),
        ),
      ).thenThrow(const PermissionFailure()),
      build: () => UsersCubit(repository),
      seed: () =>
          const UsersState(status: UsersStatus.loaded, users: [ana, omar]),
      act: (cubit) => cubit.changeRole('1', UserRole.technician),
      expect: () => [
        const UsersState(
          status: UsersStatus.loaded,
          users: [ana, omar],
          errorMessage: 'You do not have permission',
        ),
      ],
    );
  });
}
