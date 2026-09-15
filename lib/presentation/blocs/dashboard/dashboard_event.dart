import '../../../domain/entities/dashboard/comparison_item_entity.dart';

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

/// Loads one to seven independently configured comparison cards.
class LoadComparisonData extends DashboardEvent {
  LoadComparisonData({required this.items});

  final List<ComparisonItem> items;
}

class RefreshDashboard extends DashboardEvent {}

/// Clears the in-memory cache and reloads everything.
class ClearDashboardCache extends DashboardEvent {}
