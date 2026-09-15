import 'package:equatable/equatable.dart';

import '../dashboard/department_option_entity.dart';

enum DataType { quantity, value }

class TimelapseConfig extends Equatable {
  const TimelapseConfig({
    required this.departments,
    required this.fromDate,
    required this.toDate,
    required this.dataType,
    required this.durationSeconds,
  });

  final List<DepartmentOption> departments;
  final DateTime fromDate;
  final DateTime toDate;
  final DataType dataType;
  final int durationSeconds;

  factory TimelapseConfig.defaults({DateTime? now}) {
    final today = now ?? DateTime.now();
    return TimelapseConfig(
      departments: [DepartmentOption.all[2], DepartmentOption.all[3]],
      fromDate: DateTime(today.year, 1, 1),
      toDate: DateTime(today.year, today.month, today.day),
      dataType: DataType.quantity,
      durationSeconds: 60,
    );
  }

  TimelapseConfig copyWith({
    List<DepartmentOption>? departments,
    DateTime? fromDate,
    DateTime? toDate,
    DataType? dataType,
    int? durationSeconds,
  }) => TimelapseConfig(
    departments: departments ?? this.departments,
    fromDate: fromDate ?? this.fromDate,
    toDate: toDate ?? this.toDate,
    dataType: dataType ?? this.dataType,
    durationSeconds: durationSeconds ?? this.durationSeconds,
  );

  @override
  List<Object?> get props => [
    departments,
    fromDate,
    toDate,
    dataType,
    durationSeconds,
  ];
}
