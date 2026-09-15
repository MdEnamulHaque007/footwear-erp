import 'package:equatable/equatable.dart';

import '../dashboard/department_option_entity.dart';

class TimelapseDataPoint extends Equatable {
  const TimelapseDataPoint({required this.date, required this.value});

  final DateTime date;
  final double value;

  @override
  List<Object?> get props => [date, value];
}

class TimelapseSeries extends Equatable {
  const TimelapseSeries({required this.department, required this.points});

  final DepartmentOption department;
  final List<TimelapseDataPoint> points;

  double valueAt(int index) =>
      index < 0 || index >= points.length ? 0 : points[index].value;

  @override
  List<Object?> get props => [department, points];
}

class TimelapseData extends Equatable {
  const TimelapseData({
    required this.series,
    required this.fromDate,
    required this.toDate,
    required this.totalPoints,
  });

  final List<TimelapseSeries> series;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalPoints;

  @override
  List<Object?> get props => [series, fromDate, toDate, totalPoints];
}
