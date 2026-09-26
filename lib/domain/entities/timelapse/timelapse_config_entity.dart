/// ============================================================================
/// ফাইল: lib/domain/entities/timelapse/timelapse_config_entity.dart
/// স্তর: Domain Entity | মডিউল: Time-lapse Dashboard
/// উদ্দেশ্য: Time-lapse Dashboard মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: DataType, TimelapseConfig
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
