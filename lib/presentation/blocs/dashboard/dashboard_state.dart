/// ============================================================================
/// ফাইল: lib/presentation/blocs/dashboard/dashboard_state.dart
/// স্তর: Presentation BLoC | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: DashboardState, DashboardInitial, DashboardLoading, DashboardError, DashboardLoaded, DashboardPartialLoaded
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

import '../../../domain/entities/dashboard/comparison_data_entity.dart';
import '../../../domain/entities/dashboard/comparison_item_entity.dart';
import '../../../domain/entities/dashboard/comparison_matrix_entity.dart';
import '../../../domain/entities/dashboard/dashboard_activity_entity.dart';
import '../../../domain/entities/dashboard/dashboard_chart_data_entity.dart';
import '../../../domain/entities/dashboard/dashboard_quick_stats_entity.dart';
import '../../../domain/entities/dashboard/dashboard_stats_entity.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// Only the first load shows a full-page spinner; later loads keep the current
/// data on screen and flip [DashboardLoaded.isRefreshing] instead.
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Everything the screen renders in one immutable snapshot.
class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    this.stats = const DashboardStatsEntity(),
    this.activities = const [],
    this.quickStats = const DashboardQuickStatsEntity(),
    this.trend = const [],
    this.factoryComparison = const [],
    this.moduleDistribution = const [],
    this.comparisonA,
    this.comparisonB,
    this.comparisonInsight,
    this.comparisonResults = const [],
    this.comparisonMatrix,
    this.comparisonMatrixError = '',
    this.isComparisonMatrixLoading = false,
    this.isRefreshing = false,
  });

  final DashboardStatsEntity stats;
  final List<DashboardActivityEntity> activities;
  final DashboardQuickStatsEntity quickStats;
  final List<MultiSeriesDataPoint> trend;
  final List<ChartDataPoint> factoryComparison;
  final List<ChartDataPoint> moduleDistribution;

  /// Side A of the department comparison, or `null` before the user runs one.
  final ComparisonRangeEntity? comparisonA;

  /// Side B of the department comparison.
  final ComparisonRangeEntity? comparisonB;

  /// The verdict derived from A and B.
  final ComparisonInsightEntity? comparisonInsight;

  /// One result per selected department card (up to seven).
  final List<ComparisonResult> comparisonResults;

  /// Advanced X by Y aggregate, absent until the user runs it.
  final ComparisonMatrix? comparisonMatrix;
  final String comparisonMatrixError;
  final bool isComparisonMatrixLoading;

  /// True while a background refresh runs over already-visible data.
  final bool isRefreshing;

  bool get hasComparison => comparisonResults.isNotEmpty;

  DashboardLoaded copyWith({
    DashboardStatsEntity? stats,
    List<DashboardActivityEntity>? activities,
    DashboardQuickStatsEntity? quickStats,
    List<MultiSeriesDataPoint>? trend,
    List<ChartDataPoint>? factoryComparison,
    List<ChartDataPoint>? moduleDistribution,
    Object? comparisonA = _unset,
    Object? comparisonB = _unset,
    Object? comparisonInsight = _unset,
    List<ComparisonResult>? comparisonResults,
    Object? comparisonMatrix = _unset,
    String? comparisonMatrixError,
    bool? isComparisonMatrixLoading,
    bool? isRefreshing,
  }) => DashboardLoaded(
    stats: stats ?? this.stats,
    activities: activities ?? this.activities,
    quickStats: quickStats ?? this.quickStats,
    trend: trend ?? this.trend,
    factoryComparison: factoryComparison ?? this.factoryComparison,
    moduleDistribution: moduleDistribution ?? this.moduleDistribution,
    // Sentinel-based so a comparison can be explicitly cleared after a failed
    // load; a plain `??` would make the old result stick forever.
    comparisonA: comparisonA == _unset
        ? this.comparisonA
        : comparisonA as ComparisonRangeEntity?,
    comparisonB: comparisonB == _unset
        ? this.comparisonB
        : comparisonB as ComparisonRangeEntity?,
    comparisonInsight: comparisonInsight == _unset
        ? this.comparisonInsight
        : comparisonInsight as ComparisonInsightEntity?,
    comparisonResults: comparisonResults ?? this.comparisonResults,
    comparisonMatrix: comparisonMatrix == _unset
        ? this.comparisonMatrix
        : comparisonMatrix as ComparisonMatrix?,
    comparisonMatrixError: comparisonMatrixError ?? this.comparisonMatrixError,
    isComparisonMatrixLoading:
        isComparisonMatrixLoading ?? this.isComparisonMatrixLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  @override
  List<Object?> get props => [
    stats,
    activities,
    quickStats,
    trend,
    factoryComparison,
    moduleDistribution,
    comparisonA,
    comparisonB,
    comparisonInsight,
    comparisonResults,
    comparisonMatrix,
    comparisonMatrixError,
    isComparisonMatrixLoading,
    isRefreshing,
  ];
}

/// Emitted when some panels loaded and others failed, so the screen can render
/// what it has alongside a non-blocking warning.
class DashboardPartialLoaded extends DashboardLoaded {
  const DashboardPartialLoaded({
    required this.warning,
    super.stats,
    super.activities,
    super.quickStats,
    super.trend,
    super.factoryComparison,
    super.moduleDistribution,
    super.comparisonA,
    super.comparisonB,
    super.comparisonInsight,
    super.comparisonResults,
    super.comparisonMatrix,
    super.comparisonMatrixError,
    super.isComparisonMatrixLoading,
    super.isRefreshing,
  });

  final String warning;

  @override
  List<Object?> get props => [...super.props, warning];
}

/// Sentinel distinguishing "argument omitted" from "explicitly passed null",
/// so [DashboardLoaded.copyWith] can clear the nullable `comparison` field.
const Object _unset = Object();
