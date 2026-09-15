import 'package:dartz/dartz.dart';

import '../entities/dashboard/department_option_entity.dart';
import '../entities/timelapse/timelapse_config_entity.dart';
import '../entities/timelapse/timelapse_data_entity.dart';

abstract class ITimelapseRepository {
  Future<Either<String, TimelapseData>> getTimelapseData({
    required List<DepartmentOption> departments,
    required DateTime fromDate,
    required DateTime toDate,
    required DataType dataType,
  });
}
