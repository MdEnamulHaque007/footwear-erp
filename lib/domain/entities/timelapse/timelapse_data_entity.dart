/// ============================================================================
/// ফাইল: lib/domain/entities/timelapse/timelapse_data_entity.dart
/// স্তর: Domain Entity | মডিউল: Time-lapse Dashboard
/// উদ্দেশ্য: Time-lapse Dashboard মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: TimelapseDataPoint, TimelapseSeries, TimelapseData
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
