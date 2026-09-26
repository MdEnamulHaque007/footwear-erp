/// ============================================================================
/// ফাইল: lib/domain/entities/dashboard/comparison_data_entity.dart
/// স্তর: Domain Entity | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: MonthlyDataPoint, ComparisonRangeEntity, ComparisonInsightEntity
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

/// One month's total for a single department.
class MonthlyDataPoint extends Equatable {
  const MonthlyDataPoint({
    required this.month,
    required this.monthDate,
    required this.quantity,
  });

  /// Display label, e.g. `Jan 2026`.
  final String month;
  final DateTime monthDate;
  final int quantity;

  @override
  List<Object?> get props => [month, monthDate, quantity];
}

/// One side of the comparison: a department over its own date range.
class ComparisonRangeEntity extends Equatable {
  const ComparisonRangeEntity({
    required this.label,
    required this.department,
    required this.fromDate,
    required this.toDate,
    required this.totalQuantity,
    this.monthlyData = const [],
  });

  /// `Side A` or `Side B`.
  final String label;

  /// Department display name, e.g. `Cutting`.
  final String department;

  final DateTime fromDate;
  final DateTime toDate;
  final int totalQuantity;
  final List<MonthlyDataPoint> monthlyData;

  /// Number of months covered, used in the insight summary.
  int get monthCount => monthlyData.length;

  @override
  List<Object?> get props => [
    label,
    department,
    fromDate,
    toDate,
    totalQuantity,
    monthlyData,
  ];
}

/// The verdict when Side A and Side B are compared against each other.
class ComparisonInsightEntity extends Equatable {
  const ComparisonInsightEntity({
    this.departmentA = '',
    this.departmentB = '',
    this.totalA = 0,
    this.totalB = 0,
    this.growthPercent = 0,
    this.trend = 'flat',
    this.ratioA = 0,
    this.ratioB = 0,
    this.summary = '',
  });

  final String departmentA;
  final String departmentB;
  final int totalA;
  final int totalB;

  /// `(B - A) / A * 100`; `0` when A is empty rather than infinite.
  final double growthPercent;

  /// One of `up`, `down`, `flat`.
  final String trend;

  /// Each side as a 0–1 fraction of the larger, for the radial arc sweeps.
  final double ratioA;
  final double ratioB;

  final String summary;

  @override
  List<Object?> get props => [
    departmentA,
    departmentB,
    totalA,
    totalB,
    growthPercent,
    trend,
    ratioA,
    ratioB,
    summary,
  ];
}

