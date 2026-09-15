import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/dashboard/department_option_entity.dart';
import '../../domain/entities/timelapse/timelapse_config_entity.dart';
import '../../domain/entities/timelapse/timelapse_data_entity.dart';
import '../../domain/repositories/i_timelapse_repository.dart';

class TimelapseRepository implements ITimelapseRepository {
  TimelapseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _queryLimit = 1000;

  final FirebaseFirestore _firestore;

  @override
  Future<Either<String, TimelapseData>> getTimelapseData({
    required List<DepartmentOption> departments,
    required DateTime fromDate,
    required DateTime toDate,
    required DataType dataType,
  }) async {
    if (departments.isEmpty) {
      return const Left('Select at least one department.');
    }
    final from = _day(fromDate);
    final to = _day(toDate);
    if (!from.isBefore(to)) {
      return const Left('The start date must be before the end date.');
    }

    try {
      final dailyTotals = await Future.wait(
        departments.map((department) => _loadDailyTotals(
          department: department,
          from: from,
          to: to,
          dataType: dataType,
        )),
      );
      final dates = _daysBetween(from, to);
      final series = <TimelapseSeries>[
        for (var index = 0; index < departments.length; index++)
          _cumulativeSeries(departments[index], dates, dailyTotals[index]),
      ];
      return Right(
        TimelapseData(
          series: series,
          fromDate: from,
          toDate: to,
          totalPoints: dates.length,
        ),
      );
    } on FirebaseException catch (error) {
      return Left('Failed to load time-lapse data: ${error.message ?? error.code}');
    } catch (error) {
      return Left('Failed to load time-lapse data: $error');
    }
  }

  Future<Map<DateTime, double>> _loadDailyTotals({
    required DepartmentOption department,
    required DateTime from,
    required DateTime to,
    required DataType dataType,
  }) async {
    // Cutting deliberately has no monetary value. Its value timeline remains 0.
    if (dataType == DataType.value &&
        (department.label == 'Cutting' || department.valueField.isEmpty)) {
      return const {};
    }

    final field = dataType == DataType.quantity
        ? department.quantityField
        : department.valueField;
    final snapshot = await _firestore
        .collection(department.collection)
        .where(
          department.dateField,
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        )
        .where(
          department.dateField,
          isLessThanOrEqualTo: Timestamp.fromDate(
            to.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)),
          ),
        )
        .limit(_queryLimit)
        .get();

    final totals = <DateTime, double>{};
    for (final document in snapshot.docs) {
      final data = document.data();
      final date = _date(data[department.dateField]);
      if (date == null) continue;
      final day = _day(date);
      totals[day] = (totals[day] ?? 0) + _number(data[field]);
    }
    return totals;
  }

  TimelapseSeries _cumulativeSeries(
    DepartmentOption department,
    List<DateTime> dates,
    Map<DateTime, double> totals,
  ) {
    var running = 0.0;
    return TimelapseSeries(
      department: department,
      points: [
        for (final date in dates)
          TimelapseDataPoint(
            date: date,
            value: running += totals[date] ?? 0,
          ),
      ],
    );
  }

  static List<DateTime> _daysBetween(DateTime from, DateTime to) => [
    for (var day = from; !day.isAfter(to); day = day.add(const Duration(days: 1)))
      day,
  ];

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double _number(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().trim() ?? '') ?? 0;
}
