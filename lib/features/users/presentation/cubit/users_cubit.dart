import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/user_role.dart';
import '../../domain/users_repository.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._repository) : super(const UsersState());

  final UsersRepository _repository;

  Future<void> load() async {
    emit(const UsersState());
    try {
      final users = await _repository.getUsers();
      emit(UsersState(status: UsersStatus.loaded, users: users));
    } on Failure catch (failure) {
      emit(
        UsersState(status: UsersStatus.error, errorMessage: failure.message),
      );
    }
  }

  Future<void> changeRole(String userId, UserRole role) async {
    try {
      await _repository.changeRole(userId: userId, role: role);
      final users = [
        for (final user in state.users)
          user.id == userId ? user.copyWith(role: role) : user,
      ];
      emit(state.copyWith(users: users));
    } on Failure catch (failure) {
      // Keep the list on screen and report the problem.
      emit(state.copyWith(errorMessage: failure.message));
    }
  }
}
