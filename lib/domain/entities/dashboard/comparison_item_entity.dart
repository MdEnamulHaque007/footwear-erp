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
