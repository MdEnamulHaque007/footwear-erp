import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/dashboard/comparison_data_entity.dart';
import '../../../domain/entities/dashboard/dashboard_activity_entity.dart';
import '../../../domain/entities/dashboard/dashboard_chart_data_entity.dart';
import '../../../domain/entities/dashboard/dashboard_quick_stats_entity.dart';
import '../../../domain/entities/dashboard/dashboard_stats_entity.dart';
import '../../../domain/usecases/dashboard/get_comparison_data_usecase.dart';
import '../../../domain/usecases/dashboard/get_dashboard_stats_usecase.dart';
import '../../../domain/usecases/dashboard/get_factory_comparison_usecase.dart';
import '../../../domain/usecases/dashboard/get_module_distribution_usecase.dart';
import '../../../domain/usecases/dashboard/get_production_trend_usecase.dart';
import '../../../domain/usecases/dashboard/get_quick_stats_usecase.dart';
import '../../../domain/usecases/dashboard/get_recent_activities_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Aggregates every dashboard panel.
///
/// All panels are fetched in parallel; a panel that fails degrades to its empty
/// default rather than blanking the page, and the first error is surfaced as a
/// warning so the UI can say so. Results are cached in memory for [cacheTtl] so
/// returning to the dashboard does not re-query Firestore.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required this.getStats,
    required this.getRecentActivities,
    required this.getQuickStats,
    required this.getProductionTrend,
    required this.getFactoryComparison,
    required this.getModuleDistribution,
    required this.getComparisonData,
  }) : super(const DashboardInitial()) {
    on<DashboardStarted>(_onStarted);
    on<RefreshDashboard>(_onRefresh);
    on<ClearDashboardCache>(_onClearCache);
    on<LoadComparisonData>(_onLoadComparison);
    on<LoadDashboardStats>((event, emit) => _reload(emit));
    on<LoadRecentActivities>((event, emit) => _reload(emit));
    on<LoadQuickStats>((event, emit) => _reload(emit));
    on<LoadProductionTrend>((event, emit) => _reload(emit));
    on<LoadFactoryComparison>((event, emit) => _reload(emit));
    on<LoadModuleDistribution>((event, emit) => _reload(emit));
  }

  final GetDashboardStatsUseCase getStats;
  final GetRecentActivitiesUseCase getRecentActivities;
  final GetQuickStatsUseCase getQuickStats;
  final GetProductionTrendUseCase getProductionTrend;
  final GetFactoryComparisonUseCase getFactoryComparison;
  final GetModuleDistributionUseCase getModuleDistribution;
  final GetComparisonDataUseCase getComparisonData;

  /// How long a cached snapshot stays fresh.
  static const Duration cacheTtl = Duration(minutes: 15);

  /// Number of feed entries shown on the dashboard.
  static const int activityLimit = 10;

  /// Days covered by the trend chart.
  static const int trendDays = 30;

  _Cache? _cache;

  bool get hasFreshCache =>
      _cache != null && DateTime.now().difference(_cache!.at) < cacheTtl;

  // ------------------------------------------------------------- handlers

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    if (hasFreshCache) {
      emit(_cache!.snapshot);
      return;
    }
    await _reload(emit, showSpinner: true);
  }

  Future<void> _onRefresh(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    _cache = null;
    await _reload(emit);
  }

  Future<void> _onClearCache(
    ClearDashboardCache event,
    Emitter<DashboardState> emit,
  ) async {
    _cache = null;
    emit(const DashboardInitial());
  }

  /// Compares two independently chosen departments over two date ranges.
  ///
  /// Both sides are fetched in parallel; a failure clears the panel rather than
  /// emitting [DashboardError], because this runs from the panel's own
  /// `initState` and one failed range lookup must never blank the whole
  /// dashboard.
  Future<void> _onLoadComparison(
    LoadComparisonData event,
    Emitter<DashboardState> emit,
  ) async {
    final results = await Future.wait([
      getComparisonData(
        collection: event.departmentA.collection,
        dateField: event.departmentA.dateField,
        quantityField: event.departmentA.quantityField,
        fromDate: event.fromA,
        toDate: event.toA,
        label: 'Side A',
        department: event.departmentA.label,
      ),
      getComparisonData(
        collection: event.departmentB.collection,
        dateField: event.departmentB.dateField,
        quantityField: event.departmentB.quantityField,
        fromDate: event.fromB,
        toDate: event.toB,
        label: 'Side B',
        department: event.departmentB.label,
      ),
    ]);
    if (emit.isDone) return;

    final sideA = results[0].fold<ComparisonRangeEntity?>(
      (_) => null,
      (value) => value,
    );
    final sideB = results[1].fold<ComparisonRangeEntity?>(
      (_) => null,
      (value) => value,
    );
    final insight = (sideA == null || sideB == null)
        ? null
        : _buildInsight(sideA, sideB);

    final current = state;
    if (current is DashboardLoaded) {
      emit(
        current.copyWith(
          comparisonA: sideA,
          comparisonB: sideB,
          comparisonInsight: insight,
          isRefreshing: false,
        ),
      );
    } else {
      emit(
        DashboardLoaded(
          comparisonA: sideA,
          comparisonB: sideB,
          comparisonInsight: insight,
        ),
      );
    }
  }

  /// Derives the comparison verdict from the two resolved sides.
  ///
  /// Growth is B against A, so "+50%" means Side B is half again as large as
  /// Side A. An empty A yields `0` rather than infinity.
  static ComparisonInsightEntity _buildInsight(
    ComparisonRangeEntity a,
    ComparisonRangeEntity b,
  ) {
    final growth = a.totalQuantity == 0
        ? 0.0
        : ((b.totalQuantity - a.totalQuantity) / a.totalQuantity) * 100;
    final trend = growth > 5
        ? 'up'
        : growth < -5
        ? 'down'
        : 'flat';
    final maxTotal = math.max(a.totalQuantity, b.totalQuantity);
    final difference = (b.totalQuantity - a.totalQuantity).abs();
    final direction = b.totalQuantity == a.totalQuantity
        ? 'matches'
        : b.totalQuantity > a.totalQuantity
        ? 'exceeds'
        : 'trails';
    final summary = maxTotal == 0
        ? 'No records for either department in the selected ranges.'
        : '${b.department} $direction ${a.department} by '
              '${NumberFormat.decimalPattern().format(difference)} pcs '
              '(${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%).';

    return ComparisonInsightEntity(
      departmentA: a.department,
      departmentB: b.department,
      totalA: a.totalQuantity,
      totalB: b.totalQuantity,
      growthPercent: growth,
      trend: trend,
      ratioA: maxTotal == 0 ? 0 : a.totalQuantity / maxTotal,
      ratioB: maxTotal == 0 ? 0 : b.totalQuantity / maxTotal,
      summary: summary,
    );
  }

  // --------------------------------------------------------------- loading

  /// Fetches every panel in parallel.
  ///
  /// Each request is awaited individually and folded into its empty default on
  /// failure, so one broken panel cannot take the page down; the first error is
  /// surfaced as a warning so the UI can mention it without hiding the data
  /// that did load.
  Future<void> _reload(
    Emitter<DashboardState> emit, {
    bool showSpinner = false,
  }) async {
    final current = state;
    if (showSpinner && current is! DashboardLoaded) {
      emit(const DashboardLoading());
    } else if (current is DashboardLoaded) {
      emit(current.copyWith(isRefreshing: true));
    }

    final statsFuture = getStats();
    final activitiesFuture = getRecentActivities(activityLimit);
    final quickStatsFuture = getQuickStats();
    final trendFuture = getProductionTrend(trendDays);
    final factoryFuture = getFactoryComparison();
    final distributionFuture = getModuleDistribution();

    final stats = await statsFuture;
    final activities = await activitiesFuture;
    final quickStats = await quickStatsFuture;
    final trend = await trendFuture;
    final factory = await factoryFuture;
    final distribution = await distributionFuture;
    if (emit.isDone) return;

    final errors = <String>[
      ...stats.fold((e) => [e], (_) => const <String>[]),
      ...activities.fold((e) => [e], (_) => const <String>[]),
      ...quickStats.fold((e) => [e], (_) => const <String>[]),
      ...trend.fold((e) => [e], (_) => const <String>[]),
      ...factory.fold((e) => [e], (_) => const <String>[]),
      ...distribution.fold((e) => [e], (_) => const <String>[]),
    ];

    final loaded = DashboardLoaded(
      stats: stats.getOrElse(() => const DashboardStatsEntity()),
      activities: activities.getOrElse(
        () => const <DashboardActivityEntity>[],
      ),
      quickStats: quickStats.getOrElse(
        () => const DashboardQuickStatsEntity(),
      ),
      trend: trend.getOrElse(() => const <MultiSeriesDataPoint>[]),
      factoryComparison: factory.getOrElse(() => const <ChartDataPoint>[]),
      moduleDistribution: distribution.getOrElse(
        () => const <ChartDataPoint>[],
      ),
      // Comparison A/B are intentionally absent here: they are driven only by
      // the panel's own View action, so a dashboard reload must not clobber a
      // comparison the user is looking at.
    );

    // Only a fully successful snapshot is cached, so a partial result never
    // suppresses a later retry.
    if (errors.isEmpty) {
      _cache = _Cache(loaded, DateTime.now());
    }
    if (errors.isNotEmpty) {
      emit(
        DashboardPartialLoaded(
          warning: errors.first,
          stats: loaded.stats,
          activities: loaded.activities,
          quickStats: loaded.quickStats,
          trend: loaded.trend,
          factoryComparison: loaded.factoryComparison,
          moduleDistribution: loaded.moduleDistribution,
        ),
      );
    } else {
      emit(loaded);
    }
  }
}

/// Cached snapshot plus the moment it was taken, for the TTL check.
class _Cache {
  const _Cache(this.snapshot, this.at);
  final DashboardLoaded snapshot;
  final DateTime at;
}
