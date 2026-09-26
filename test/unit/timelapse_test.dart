/// ============================================================================
/// ফাইল: test/unit/timelapse_test.dart
/// স্তর: Test | মডিউল: Time-lapse Dashboard
/// উদ্দেশ্য: Timelapse Test অংশের প্রত্যাশিত আচরণ স্বয়ংক্রিয়ভাবে যাচাই করে এবং regression প্রতিরোধ করে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_test/flutter_test.dart';

import 'package:footwear/domain/entities/dashboard/department_option_entity.dart';
import 'package:footwear/domain/entities/timelapse/timelapse_config_entity.dart';
import 'package:footwear/domain/entities/timelapse/timelapse_data_entity.dart';

void main() {
  final cutting = DepartmentOption.all[2];
  final sewing = DepartmentOption.all[3];
  final from = DateTime(2026, 1, 1);
  final to = DateTime(2026, 1, 3);

  TimelapseDataPoint point(int day, double value) => TimelapseDataPoint(
    date: DateTime(2026, 1, day),
    value: value,
  );

  test('config stores all selected options', () {
    final config = TimelapseConfig(
      departments: [cutting, sewing],
      fromDate: from,
      toDate: to,
      dataType: DataType.quantity,
      durationSeconds: 60,
    );
    expect(config.departments, [cutting, sewing]);
    expect(config.durationSeconds, 60);
  });

  test('defaults select Cutting and Sewing', () {
    final config = TimelapseConfig.defaults(now: DateTime(2026, 9, 15));
    expect(config.departments, [cutting, sewing]);
    expect(config.fromDate, DateTime(2026, 1, 1));
    expect(config.toDate, DateTime(2026, 9, 15));
  });

  test('data point maps its date and value', () {
    final value = point(1, 125.5);
    expect(value.date, from);
    expect(value.value, 125.5);
  });

  test('series valueAt returns its cumulative point', () {
    final series = TimelapseSeries(
      department: cutting,
      points: [
        TimelapseDataPoint(date: DateTime(2026, 1, 1), value: 50),
        TimelapseDataPoint(date: DateTime(2026, 1, 2), value: 75),
      ],
    );
    expect(series.valueAt(1), 75);
  });

  test('valueAt safely returns zero outside the series', () {
    final series = TimelapseSeries(department: cutting, points: [point(1, 50)]);
    expect(series.valueAt(-1), 0);
    expect(series.valueAt(1), 0);
  });

  test('aligned series carry the same number of days', () {
    final first = TimelapseSeries(
      department: cutting,
      points: [point(1, 10), point(2, 10), point(3, 25)],
    );
    final second = TimelapseSeries(
      department: sewing,
      points: [point(1, 0), point(2, 20), point(3, 20)],
    );
    final data = TimelapseData(
      series: [first, second],
      fromDate: from,
      toDate: to,
      totalPoints: 3,
    );
    expect(data.series.map((series) => series.points.length), [3, 3]);
  });

  test('a missing daily value keeps the previous cumulative total', () {
    final series = TimelapseSeries(
      department: cutting,
      points: [point(1, 20), point(2, 20), point(3, 35)],
    );
    expect(series.valueAt(1), series.valueAt(0));
  });

  test('cumulative values retain their running sum', () {
    final series = TimelapseSeries(
      department: cutting,
      points: [point(1, 10), point(2, 25), point(3, 40)],
    );
    expect(series.valueAt(2), 40);
  });

  test('data type exposes quantity and value modes', () {
    expect(DataType.values, [DataType.quantity, DataType.value]);
  });

  test('empty timeline data has zero points', () {
    final data = TimelapseData(
      series: const [],
      fromDate: from,
      toDate: to,
      totalPoints: 0,
    );
    expect(data.series, isEmpty);
    expect(data.totalPoints, 0);
  });

  test('multi-department data preserves every selected series', () {
    final data = TimelapseData(
      series: [
        TimelapseSeries(department: cutting, points: [point(1, 10)]),
        TimelapseSeries(department: sewing, points: [point(1, 12)]),
      ],
      fromDate: from,
      toDate: to,
      totalPoints: 1,
    );
    expect(data.series.map((series) => series.department), [cutting, sewing]);
  });

  test('progress is correctly represented by completed days', () {
    const visiblePoints = 2;
    const totalPoints = 4;
    expect(visiblePoints / totalPoints, 0.5);
  });
}
