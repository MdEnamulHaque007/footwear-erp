/// ============================================================================
/// ফাইল: lib/presentation/blocs/user_management/user_management_state.dart
/// স্তর: Presentation BLoC | মডিউল: User Management
/// উদ্দেশ্য: User Management screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: UserManagementState, UserManagementInitial, UserManagementLoading, UserManagementLoaded, UserManagementLoadingMore, UserSearchLoaded, UserDetailLoading, UserDetailLoaded, UserManagementSuccess, UserManagementError
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/user_entity.dart';

sealed class UserManagementState {}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UserManagementLoaded extends UserManagementState {
  UserManagementLoaded(
    this.users, {
    this.hasMore = false,
    this.currentPage = 0,
  });
  final List<UserEntity> users;

  /// True when another page is available, which drives the load-more trigger.
  final bool hasMore;
  final int currentPage;
}

/// A page fetch is in flight while the current rows stay on screen.
class UserManagementLoadingMore extends UserManagementState {
  UserManagementLoadingMore(this.users, {this.currentPage = 0});
  final List<UserEntity> users;
  final int currentPage;
}

/// A filtered view of the loaded rows.
class UserSearchLoaded extends UserManagementLoaded {
  UserSearchLoaded(
    super.users, {
    super.hasMore,
    super.currentPage,
    required this.query,
  });
  final String query;
}

class UserDetailLoading extends UserManagementState {}

class UserDetailLoaded extends UserManagementState {
  UserDetailLoaded(this.user);
  final UserEntity user;
}

class UserManagementSuccess extends UserManagementState {
  UserManagementSuccess(this.message);
  final String message;
}

class UserManagementError extends UserManagementState {
  UserManagementError(this.message);
  final String message;
}
