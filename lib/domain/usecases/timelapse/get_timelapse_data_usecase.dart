import 'package:dartz/dartz.dart';

import '../../entities/timelapse/timelapse_config_entity.dart';
import '../../entities/timelapse/timelapse_data_entity.dart';
import '../../repositories/i_timelapse_repository.dart';

class GetTimelapseDataUseCase {
  GetTimelapseDataUseCase(this._repository);

  final ITimelapseRepository _repository;

  Future<Either<String, TimelapseData>> call(TimelapseConfig config) {
    return _repository.getTimelapseData(
      departments: config.departments,
      fromDate: config.fromDate,
      toDate: config.toDate,
      dataType: config.dataType,
    );
  }
}
