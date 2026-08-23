import '../../../domain/entities/user_entity.dart';

sealed class UserManagementEvent {}

class LoadUsers extends UserManagementEvent {}

class UsersUpdated extends UserManagementEvent {
  UsersUpdated(this.users);
  final List<UserEntity> users;
}

class UpdateUserRole extends UserManagementEvent {
  UpdateUserRole(this.uid, this.role);
  final String uid;
  final String role;
}

class UpdateUserPermissions extends UserManagementEvent {
  UpdateUserPermissions(this.uid, this.permissions);
  final String uid;
  final Map<String, dynamic> permissions;
}

class UpdateUserStatus extends UserManagementEvent {
  UpdateUserStatus(this.uid, this.active);
  final String uid;
  final bool active;
}

class DeleteUser extends UserManagementEvent {
  DeleteUser(this.uid);
  final String uid;
}
