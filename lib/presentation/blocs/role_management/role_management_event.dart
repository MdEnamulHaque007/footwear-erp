/// ============================================================================
/// ফাইল: lib/presentation/blocs/role_management/role_management_event.dart
/// স্তর: Presentation BLoC | মডিউল: Role Management
/// উদ্দেশ্য: Role Management screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: RoleManagementEvent, LoadRoles, RolesUpdated, CreateRole, UpdateRolePermissions, DeleteRole
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
