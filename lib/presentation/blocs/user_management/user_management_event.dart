import '../../../domain/entities/user_entity.dart';

sealed class UserManagementEvent {}

class LoadUsers extends UserManagementEvent {
  LoadUsers({this.limit = 20});
  final int limit;
}

/// Fetches the next page, appending to the rows already loaded.
class LoadMoreUsers extends UserManagementEvent {}

class SearchUsers extends UserManagementEvent {
  SearchUsers(this.query);
  final String query;
}

class ClearSearchUsers extends UserManagementEvent {}

class RefreshUsers extends UserManagementEvent {}

/// Loads one profile for the detail / edit screens.
class LoadUserDetail extends UserManagementEvent {
  LoadUserDetail(this.uid, {this.initialUser});
  final String uid;
  final UserEntity? initialUser;
}

class UsersUpdated extends UserManagementEvent {
  UsersUpdated(this.users);
  final List<UserEntity> users;
}

class UpdateUserRole extends UserManagementEvent {
  UpdateUserRole(this.uid, this.role);
  final String uid;
  final String role;
}

/// Updates role + status + permissions together (transaction).
class UpdateUser extends UserManagementEvent {
  UpdateUser(this.user);
  final UserEntity user;
}

class UpdateUserPermissions extends UserManagementEvent {
  UpdateUserPermissions(this.uid, this.permissions);
  final String uid;
  final Map<String, Map<String, bool>> permissions;
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
