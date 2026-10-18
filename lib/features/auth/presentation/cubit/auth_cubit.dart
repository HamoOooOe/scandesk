import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/auth_repository.dart';
import 'auth_state.dart';

/// Holds who is logged in. Registered once in get_it and shared by the
/// whole app; the router listens to it to decide which screen to show.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  /// Called once on app start.
  Future<void> checkSession() async {
    try {
      final user = await _repository.getCurrentUser();
      emit(user == null ? const Unauthenticated() : Authenticated(user));
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const Authenticating());
    try {
      final user = await _repository.signIn(email: email, password: password);
      emit(Authenticated(user));
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } on Failure {
      // Even if the request fails, clear the local state.
    }
    emit(const Unauthenticated());
  }
}
