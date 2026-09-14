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
