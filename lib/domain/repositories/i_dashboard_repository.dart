import 'package:dartz/dartz.dart';
import '../entities/dashboard/comparison_data_entity.dart';
import '../entities/dashboard/dashboard_activity_entity.dart';
import '../entities/dashboard/dashboard_chart_data_entity.dart';
import '../entities/dashboard/dashboard_quick_stats_entity.dart';
import '../entities/dashboard/dashboard_stats_entity.dart';

abstract interface class IDashboardRepository {
  /// Counts and summed values for every production collection.
  Future<Either<String, DashboardStatsEntity>> getStats();

  /// Newest entries merged across all collections, newest first.
  Future<Either<String, List<DashboardActivityEntity>>> getRecentActivities(
    int limit,
  );

  /// Today / week / month rolling totals.
  Future<Either<String, DashboardQuickStatsEntity>> getQuickStats();

  /// Daily quantity per stage for the last [days] days.
  Future<Either<String, List<MultiSeriesDataPoint>>> getProductionTrend(
    int days,
  );

  /// Total quantity produced per factory.
  Future<Either<String, List<ChartDataPoint>>> getFactoryComparison();

  /// Record count per module, as percentages of the total.
  Future<Either<String, List<ChartDataPoint>>> getModuleDistribution();

  /// One side of the department comparison: totals for [quantityField] of
  /// [collection] whose [dateField] falls within `fromDate`..`toDate`, grouped
  /// by month.
  ///
  /// The collection/field names are supplied by the caller (see
  /// `DepartmentOption`) so any two stages can be compared over independent
  /// ranges without this interface knowing them.
  Future<Either<String, ComparisonRangeEntity>> getComparisonData({
    required String collection,
    required String dateField,
    required String quantityField,
    required DateTime fromDate,
    required DateTime toDate,
    required String label,
    required String department,
  });
}
