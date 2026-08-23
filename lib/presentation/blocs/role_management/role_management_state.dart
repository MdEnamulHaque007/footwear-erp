import '../../../domain/entities/role_entity.dart';

sealed class RoleManagementState {}

class RoleManagementInitial extends RoleManagementState {}

class RoleManagementLoading extends RoleManagementState {}

class RoleManagementLoaded extends RoleManagementState {
  RoleManagementLoaded(this.roles);
  final List<RoleEntity> roles;
}

class RoleManagementSuccess extends RoleManagementState {
  RoleManagementSuccess(this.message);
  final String message;
}

class RoleManagementError extends RoleManagementState {
  RoleManagementError(this.message);
  final String message;
}
