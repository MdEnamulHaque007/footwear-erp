import '../../../domain/entities/role_entity.dart';

sealed class RoleManagementEvent {}

class LoadRoles extends RoleManagementEvent {}

class RolesUpdated extends RoleManagementEvent {
  RolesUpdated(this.roles);
  final List<RoleEntity> roles;
}

class CreateRole extends RoleManagementEvent {
  CreateRole(this.name, this.permissions);
  final String name;
  final Map<String, Map<String, bool>> permissions;
}

class UpdateRolePermissions extends RoleManagementEvent {
  UpdateRolePermissions(this.roleId, this.permissions);
  final String roleId;
  final Map<String, Map<String, bool>> permissions;
}

class DeleteRole extends RoleManagementEvent {
  DeleteRole(this.roleId);
  final String roleId;
}
