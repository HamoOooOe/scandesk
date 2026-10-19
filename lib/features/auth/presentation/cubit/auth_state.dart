import 'package:equatable/equatable.dart';

import '../../domain/app_user.dart';

/// Every situation the auth flow can be in. `sealed` means the compiler
/// knows this list is complete, so a `switch` over it must handle all cases.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// App just started; checking for a saved session.
class AuthInitial extends AuthState {
  const AuthInitial();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Login request in progress (the login button shows a spinner).
class Authenticating extends AuthState {
  const Authenticating();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  final AppUser user;

  @override
  List<Object?> get props => [user];
}

/// Account created. Supabase may require the user to confirm their email
/// before logging in, so we send them back to the login screen.
class SignUpSuccess extends AuthState {
  const SignUpSuccess();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
