abstract class DashboardState {}
class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final int totalUsers;
  final int totalRoles;
  final int activeUsers;
  DashboardLoaded({
    required this.totalUsers,
    required this.totalRoles,
    required this.activeUsers,
  });
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
