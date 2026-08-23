import '../../../domain/entities/user_entity.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  Authenticated(this.user);
  final UserEntity user;
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}

class RegisterSuccess extends AuthState {}

class ResetPasswordSent extends AuthState {}
