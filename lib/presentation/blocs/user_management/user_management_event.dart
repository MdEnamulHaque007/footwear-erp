/// ============================================================================
/// ফাইল: lib/presentation/blocs/user_management/user_management_event.dart
/// স্তর: Presentation BLoC | মডিউল: User Management
/// উদ্দেশ্য: User Management screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: UserManagementEvent, LoadUsers, LoadMoreUsers, SearchUsers, ClearSearchUsers, RefreshUsers, LoadUserDetail, UsersUpdated, UpdateUserRole, UpdateUser
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
