import 'package:equatable/equatable.dart';

/// A failure is an expected error the UI knows how to show
/// (no internet, wrong password, permission denied...).
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error, please try again']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'You do not have permission']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong']);
}
