import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/auth_repository.dart';
import 'auth_state.dart';

/// Holds who is logged in. Registered once in get_it and shared by the
/// whole app; the router listens to it to decide which screen to show.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial()) {
    // If the session ends later (expired token...), send the user to login.
    _signedOutSubscription = _repository.onSignedOut.listen((_) {
      if (state is Authenticated) emit(const Unauthenticated());
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _signedOutSubscription;

  @override
  Future<void> close() {
    _signedOutSubscription.cancel();
    return super.close();
  }

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

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    emit(const Authenticating());
    try {
      await _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      emit(const SignUpSuccess());
    } on Failure catch (failure) {
      emit(AuthError(failure.message));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    emit(const Authenticating());
    try {
      await _repository.sendPasswordReset(email);
      emit(const PasswordResetSent());
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
