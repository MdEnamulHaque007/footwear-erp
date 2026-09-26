/// ============================================================================
/// ফাইল: lib/presentation/blocs/dashboard/dashboard_bloc.dart
/// স্তর: Presentation BLoC | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: DashboardBloc, _Cache
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/dashboard/comparison_data_entity.dart';
import '../../../domain/entities/dashboard/comparison_item_entity.dart';
import '../../../domain/entities/dashboard/dashboard_activity_entity.dart';
import '../../../domain/entities/dashboard/dashboard_chart_data_entity.dart';
import '../../../domain/entities/dashboard/dashboard_quick_stats_entity.dart';
import '../../../domain/entities/dashboard/dashboard_stats_entity.dart';
import '../../../domain/usecases/dashboard/get_comparison_data_usecase.dart';
import '../../../domain/usecases/dashboard/get_comparison_matrix_usecase.dart';
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
    required this.getComparisonMatrix,
  }) : super(const DashboardInitial()) {
    on<DashboardStarted>(_onStarted);
    on<RefreshDashboard>(_onRefresh);
    on<ClearDashboardCache>(_onClearCache);
    on<LoadComparisonData>(_onLoadComparison);
    on<LoadComparisonMatrix>(_onLoadComparisonMatrix);
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
  final GetComparisonMatrixUseCase getComparisonMatrix;

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

  /// Resolves one to seven independently configured department cards in
  /// parallel. A failed card is omitted without blanking the dashboard.
  ///
  /// Both sides are fetched in parallel; a failure clears the panel rather than
  /// emitting [DashboardError], because this runs from the panel's own
  /// `initState` and one failed range lookup must never blank the whole
  /// dashboard.
  Future<void> _onLoadComparison(
    LoadComparisonData event,
    Emitter<DashboardState> emit,
  ) async {
    final items = event.items.take(7).toList();
    final results = await Future.wait<ComparisonResult?>(
      items.map((item) async {
        final result = await getComparisonData(
          collection: item.department.collection,
          dateField: item.department.dateField,
          quantityField: item.department.quantityField,
          fromDate: item.fromDate,
          toDate: item.toDate,
          label: item.id,
          department: item.department.label,
        );
        return result.fold<ComparisonResult?>(
          (_) => null,
          (data) => ComparisonResult(item: item, data: data),
        );
      }),
    );
    if (emit.isDone) return;
    final comparisonResults = results.whereType<ComparisonResult>().toList();
    final sideA = comparisonResults.isEmpty ? null : comparisonResults.first.data;
    final sideB = comparisonResults.length < 2 ? null : comparisonResults[1].data;
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
          comparisonResults: comparisonResults,
          isRefreshing: false,
        ),
      );
    } else {
      emit(
        DashboardLoaded(
          comparisonA: sideA,
          comparisonB: sideB,
          comparisonInsight: insight,
          comparisonResults: comparisonResults,
        ),
      );
    }
  }

  Future<void> _onLoadComparisonMatrix(
    LoadComparisonMatrix event,
    Emitter<DashboardState> emit,
  ) async {
    final current = state;
    final snapshot = current is DashboardLoaded
        ? current
        : const DashboardLoaded();
    emit(
      snapshot.copyWith(
        isComparisonMatrixLoading: true,
        comparisonMatrixError: '',
      ),
    );

    final result = await getComparisonMatrix(
      collections: event.collections,
      dateFields: event.dateFields,
      xCriteria: event.xCriteria,
      yCriteria: event.yCriteria,
      valueType: event.valueType,
      fromDate: event.fromDate,
      toDate: event.toDate,
    );
    if (emit.isDone) return;

    result.fold(
      (error) => emit(
        snapshot.copyWith(
          comparisonMatrix: null,
          comparisonMatrixError: error,
          isComparisonMatrixLoading: false,
        ),
      ),
      (matrix) => emit(
        snapshot.copyWith(
          comparisonMatrix: matrix,
          comparisonMatrixError: '',
          isComparisonMatrixLoading: false,
        ),
      ),
    );
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

    final previous = current is DashboardLoaded ? current : null;

    // Stage 1: KPI cards are the first useful visual response.
    final stats = await getStats();
    if (emit.isDone) return;
    final statsError = stats.fold((error) => error, (_) => '');
    final stageOne = DashboardPartialLoaded(
      warning: statsError,
      stats: stats.getOrElse(() => const DashboardStatsEntity()),
      comparisonA: previous?.comparisonA,
      comparisonB: previous?.comparisonB,
      comparisonInsight: previous?.comparisonInsight,
      comparisonResults: previous?.comparisonResults ?? const [],
      comparisonMatrix: previous?.comparisonMatrix,
      comparisonMatrixError: previous?.comparisonMatrixError ?? '',
      isComparisonMatrixLoading: previous?.isComparisonMatrixLoading ?? false,
    );
    emit(stageOne);

    // Stage 2: delay non-critical chart work until the KPI frame can paint.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (emit.isDone) return;
    final trendFuture = getProductionTrend(trendDays);
    final factoryFuture = getFactoryComparison();
    final distributionFuture = getModuleDistribution();
    await Future.wait<void>([
      trendFuture.then<void>((_) {}),
      factoryFuture.then<void>((_) {}),
      distributionFuture.then<void>((_) {}),
    ]);
    if (emit.isDone) return;
    final trend = await trendFuture;
    final factory = await factoryFuture;
    final distribution = await distributionFuture;
    final chartErrors = <String>[
      ...trend.fold((error) => [error], (_) => const <String>[]),
      ...factory.fold((error) => [error], (_) => const <String>[]),
      ...distribution.fold((error) => [error], (_) => const <String>[]),
    ];
    final stageTwo = DashboardPartialLoaded(
      warning: statsError.isNotEmpty
          ? statsError
          : chartErrors.isEmpty
          ? ''
          : chartErrors.first,
      stats: stageOne.stats,
      trend: trend.getOrElse(() => const <MultiSeriesDataPoint>[]),
      factoryComparison: factory.getOrElse(() => const <ChartDataPoint>[]),
      moduleDistribution: distribution.getOrElse(
        () => const <ChartDataPoint>[],
      ),
      comparisonA: previous?.comparisonA,
      comparisonB: previous?.comparisonB,
      comparisonInsight: previous?.comparisonInsight,
      comparisonResults: previous?.comparisonResults ?? const [],
      comparisonMatrix: previous?.comparisonMatrix,
      comparisonMatrixError: previous?.comparisonMatrixError ?? '',
      isComparisonMatrixLoading: previous?.isComparisonMatrixLoading ?? false,
    );
    emit(stageTwo);

    // Stage 3: the lower-page feed and summary arrive after first paint.
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (emit.isDone) return;
    final activitiesFuture = getRecentActivities(activityLimit);
    final quickStatsFuture = getQuickStats();
    await Future.wait<void>([
      activitiesFuture.then<void>((_) {}),
      quickStatsFuture.then<void>((_) {}),
    ]);
    if (emit.isDone) return;
    final activities = await activitiesFuture;
    final quickStats = await quickStatsFuture;
    final finalErrors = <String>[
      statsError,
      ...chartErrors,
      ...activities.fold((error) => [error], (_) => const <String>[]),
      ...quickStats.fold((error) => [error], (_) => const <String>[]),
    ].where((error) => error.isNotEmpty).toList();

    final loaded = DashboardLoaded(
      stats: stageTwo.stats,
      activities: activities.getOrElse(() => const <DashboardActivityEntity>[]),
      quickStats: quickStats.getOrElse(() => const DashboardQuickStatsEntity()),
      trend: stageTwo.trend,
      factoryComparison: stageTwo.factoryComparison,
      moduleDistribution: stageTwo.moduleDistribution,
      comparisonA: previous?.comparisonA,
      comparisonB: previous?.comparisonB,
      comparisonInsight: previous?.comparisonInsight,
      comparisonResults: previous?.comparisonResults ?? const [],
      comparisonMatrix: previous?.comparisonMatrix,
      comparisonMatrixError: previous?.comparisonMatrixError ?? '',
      isComparisonMatrixLoading: previous?.isComparisonMatrixLoading ?? false,
    );
    if (finalErrors.isEmpty) _cache = _Cache(loaded, DateTime.now());
    emit(
      finalErrors.isEmpty
          ? loaded
          : DashboardPartialLoaded(
              warning: finalErrors.first,
              stats: loaded.stats,
              activities: loaded.activities,
              quickStats: loaded.quickStats,
              trend: loaded.trend,
              factoryComparison: loaded.factoryComparison,
              moduleDistribution: loaded.moduleDistribution,
              comparisonA: loaded.comparisonA,
              comparisonB: loaded.comparisonB,
              comparisonInsight: loaded.comparisonInsight,
              comparisonResults: loaded.comparisonResults,
              comparisonMatrix: loaded.comparisonMatrix,
              comparisonMatrixError: loaded.comparisonMatrixError,
              isComparisonMatrixLoading: loaded.isComparisonMatrixLoading,
            ),
    );
  }
}

/// Cached snapshot plus the moment it was taken, for the TTL check.
class _Cache {
  const _Cache(this.snapshot, this.at);
  final DashboardLoaded snapshot;
  final DateTime at;
}
