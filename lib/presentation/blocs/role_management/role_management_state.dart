/// ============================================================================
/// ফাইল: lib/presentation/blocs/role_management/role_management_state.dart
/// স্তর: Presentation BLoC | মডিউল: Role Management
/// উদ্দেশ্য: Role Management screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: RoleManagementState, RoleManagementInitial, RoleManagementLoading, RoleManagementLoaded, RoleManagementSuccess, RoleManagementError
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
