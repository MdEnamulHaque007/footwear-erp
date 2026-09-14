import '../../../domain/entities/user_entity.dart';

sealed class AuthEvent {}

class AuthStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  LoginRequested(this.email, this.password);
  final String email;
  final String password;
}

class RegisterRequested extends AuthEvent {
  RegisterRequested(this.name, this.email, this.password);
  final String name;
  final String email;
  final String password;
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

/// Debug-only: authenticate as the in-memory dev user (see `DevConfig`).
class DevSkipLoginRequested extends AuthEvent {}

class ResetPasswordRequested extends AuthEvent {
  ResetPasswordRequested(this.email);
  final String email;
}

class AuthProfileUpdated extends AuthEvent {
  AuthProfileUpdated(this.user);
  final UserEntity user;
}

class AuthStateChanged extends AuthEvent {
  AuthStateChanged(this.user);
  final UserEntity? user;
}
