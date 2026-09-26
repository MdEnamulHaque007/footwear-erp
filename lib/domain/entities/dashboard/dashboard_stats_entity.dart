/// ============================================================================
/// ফাইল: lib/domain/entities/dashboard/dashboard_stats_entity.dart
/// স্তর: Domain Entity | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: DashboardStatsEntity
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

/// Aggregate counts and values across every production collection.
///
/// One instance describes the whole dashboard's KPI row, so the screen needs a
/// single round-trip through the repository rather than one per module.
class DashboardStatsEntity extends Equatable {
  const DashboardStatsEntity({
    this.masterLcCount = 0,
    this.masterLcValue = 0,
    this.poCount = 0,
    this.poValue = 0,
    this.cuttingCount = 0,
    this.cuttingQuantity = 0,
    this.sewingCount = 0,
    this.sewingQuantity = 0,
    this.productionCount = 0,
    this.productionQuantity = 0,
    this.issueCount = 0,
    this.issueQuantity = 0,
    this.exportCount = 0,
    this.exportQuantity = 0,
    this.userCount = 0,
    this.activeUserCount = 0,
  });

  /// Zeroed stats, used before the first load completes and as the `fold`
  /// fallback when a query fails so the KPI row still renders.
  factory DashboardStatsEntity.defaults() => const DashboardStatsEntity();

  final int masterLcCount;
  final double masterLcValue;
  final int poCount;
  final double poValue;
  final int cuttingCount;
  final int cuttingQuantity;
  final int sewingCount;
  final int sewingQuantity;
  final int productionCount;
  final int productionQuantity;
  final int issueCount;
  final int issueQuantity;
  final int exportCount;
  final int exportQuantity;
  final int userCount;
  final int activeUserCount;

  /// Total documents across the seven production collections.
  int get totalRecords =>
      masterLcCount +
      poCount +
      cuttingCount +
      sewingCount +
      productionCount +
      issueCount +
      exportCount;

  /// Total produced/processed pieces across the five quantity-bearing stages.
  int get totalQuantity =>
      cuttingQuantity +
      sewingQuantity +
      productionQuantity +
      issueQuantity +
      exportQuantity;

  /// Combined monetary value of Master LC and Purchase Orders.
  double get totalValue => masterLcValue + poValue;

  DashboardStatsEntity copyWith({
    int? masterLcCount,
    double? masterLcValue,
    int? poCount,
    double? poValue,
    int? cuttingCount,
    int? cuttingQuantity,
    int? sewingCount,
    int? sewingQuantity,
    int? productionCount,
    int? productionQuantity,
    int? issueCount,
    int? issueQuantity,
    int? exportCount,
    int? exportQuantity,
    int? userCount,
    int? activeUserCount,
  }) => DashboardStatsEntity(
    masterLcCount: masterLcCount ?? this.masterLcCount,
    masterLcValue: masterLcValue ?? this.masterLcValue,
    poCount: poCount ?? this.poCount,
    poValue: poValue ?? this.poValue,
    cuttingCount: cuttingCount ?? this.cuttingCount,
    cuttingQuantity: cuttingQuantity ?? this.cuttingQuantity,
    sewingCount: sewingCount ?? this.sewingCount,
    sewingQuantity: sewingQuantity ?? this.sewingQuantity,
    productionCount: productionCount ?? this.productionCount,
    productionQuantity: productionQuantity ?? this.productionQuantity,
    issueCount: issueCount ?? this.issueCount,
    issueQuantity: issueQuantity ?? this.issueQuantity,
    exportCount: exportCount ?? this.exportCount,
    exportQuantity: exportQuantity ?? this.exportQuantity,
    userCount: userCount ?? this.userCount,
    activeUserCount: activeUserCount ?? this.activeUserCount,
  );

  @override
  List<Object?> get props => [
    masterLcCount,
    masterLcValue,
    poCount,
    poValue,
    cuttingCount,
    cuttingQuantity,
    sewingCount,
    sewingQuantity,
    productionCount,
    productionQuantity,
    issueCount,
    issueQuantity,
    exportCount,
    exportQuantity,
    userCount,
    activeUserCount,
  ];
}
