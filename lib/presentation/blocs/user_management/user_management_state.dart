import '../../../domain/entities/user_entity.dart';

sealed class UserManagementState {}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UserManagementLoaded extends UserManagementState {
  UserManagementLoaded(this.users);
  final List<UserEntity> users;
}

class UserManagementSuccess extends UserManagementState {
  UserManagementSuccess(this.message);
  final String message;
}

class UserManagementError extends UserManagementState {
  UserManagementError(this.message);
  final String message;
}
