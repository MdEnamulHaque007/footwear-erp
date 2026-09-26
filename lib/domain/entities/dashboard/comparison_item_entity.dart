/// ============================================================================
/// ফাইল: lib/domain/entities/dashboard/comparison_item_entity.dart
/// স্তর: Domain Entity | মডিউল: Dashboard
/// উদ্দেশ্য: Dashboard মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: ChartType, ChartTypeLabel, ComparisonItem, ComparisonResult
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

import 'comparison_data_entity.dart';
import 'department_option_entity.dart';

enum ChartType { line, bar, pie, area, radar }

extension ChartTypeLabel on ChartType {
  String get label => switch (this) {
    ChartType.line => 'Line',
    ChartType.bar => 'Bar',
    ChartType.pie => 'Pie',
    ChartType.area => 'Area',
    ChartType.radar => 'Radar',
  };
}

class ComparisonItem extends Equatable {
  const ComparisonItem({
    required this.id,
    required this.department,
    required this.fromDate,
    required this.toDate,
    this.chartType = ChartType.line,
  });

  final String id;
  final DepartmentOption department;
  final DateTime fromDate;
  final DateTime toDate;
  final ChartType chartType;

  ComparisonItem copyWith({
    DepartmentOption? department,
    DateTime? fromDate,
    DateTime? toDate,
    ChartType? chartType,
  }) => ComparisonItem(
    id: id,
    department: department ?? this.department,
    fromDate: fromDate ?? this.fromDate,
    toDate: toDate ?? this.toDate,
    chartType: chartType ?? this.chartType,
  );

  @override
  List<Object?> get props => [id, department, fromDate, toDate, chartType];
}

class ComparisonResult extends Equatable {
  const ComparisonResult({required this.item, required this.data});

  final ComparisonItem item;
  final ComparisonRangeEntity data;

  @override
  List<Object?> get props => [item, data];
}
