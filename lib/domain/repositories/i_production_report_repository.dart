import 'package:dartz/dartz.dart';
import '../entities/reports/production_report_entity.dart';

abstract interface class IProductionReportRepository {
  /// Builds the Production Report for [fromDate]..[toDate].
  ///
  /// Lines are discovered from the Cutting / Sewing / Production collections
  /// inside the date range, then joined against the Purchase Orders for
  /// company / project / ordered quantity. [search] filters the result
  /// case-insensitively across company, project, PO, article and color.
  Future<Either<String, List<ProductionReportEntity>>> getProductionReport({
    required DateTime fromDate,
    required DateTime toDate,
    String search = '',
  });

  /// Grand totals for [fromDate]..[toDate] (the sheet's TOTAL row).
  Future<Either<String, ProductionReportSummary>> getReportSummary({
    required DateTime fromDate,
    required DateTime toDate,
    String search = '',
  });
}
