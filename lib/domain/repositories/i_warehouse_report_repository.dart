import 'package:dartz/dartz.dart';

import '../entities/reports/warehouse_report_entity.dart';

abstract interface class IWarehouseReportRepository {
  Future<Either<String, WarehouseReportResult>> getWarehouseReport({
    required DateTime fromDate,
    required DateTime toDate,
  });
}
