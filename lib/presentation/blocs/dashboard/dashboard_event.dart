import '../../../domain/entities/dashboard/department_option_entity.dart';

sealed class DashboardEvent {}

class DashboardStarted extends DashboardEvent {}

class LoadDashboardStats extends DashboardEvent {}

class LoadRecentActivities extends DashboardEvent {}

class LoadQuickStats extends DashboardEvent {}

class LoadProductionTrend extends DashboardEvent {
  LoadProductionTrend({this.days = 30});
  final int days;
}

class LoadFactoryComparison extends DashboardEvent {}

class LoadModuleDistribution extends DashboardEvent {}

/// Compares two user-chosen departments over two independent date ranges.
class LoadComparisonData extends DashboardEvent {
  LoadComparisonData({
    required this.departmentA,
    required this.departmentB,
    required this.fromA,
    required this.toA,
    required this.fromB,
    required this.toB,
  });

  final DepartmentOption departmentA;
  final DepartmentOption departmentB;
  final DateTime fromA;
  final DateTime toA;
  final DateTime fromB;
  final DateTime toB;
}

class RefreshDashboard extends DashboardEvent {}

/// Clears the in-memory cache and reloads everything.
class ClearDashboardCache extends DashboardEvent {}

