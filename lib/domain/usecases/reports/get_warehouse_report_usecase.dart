import 'package:dartz/dartz.dart';

import '../../entities/reports/warehouse_report_entity.dart';
import '../../repositories/i_warehouse_report_repository.dart';

class GetWarehouseReportUseCase {
  const GetWarehouseReportUseCase(this._repository);

  final IWarehouseReportRepository _repository;

  Future<Either<String, WarehouseReportResult>> call({
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    if (toDate.isBefore(fromDate)) {
      return Future.value(const Left('To date must be after From date'));
    }
    return _repository.getWarehouseReport(fromDate: fromDate, toDate: toDate);
  }
}
