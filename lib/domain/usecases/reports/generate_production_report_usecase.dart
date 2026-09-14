import 'package:dartz/dartz.dart';
import '../../entities/reports/production_report_entity.dart';
import '../../repositories/i_production_report_repository.dart';

/// Generates the Production Report: rows + grand total for one date range.
class GenerateProductionReportUseCase {
  GenerateProductionReportUseCase(this._repository);
  final IProductionReportRepository _repository;

  Future<Either<String, ProductionReportResult>> call({
    required DateTime fromDate,
    required DateTime toDate,
    String search = '',
  }) async {
    if (toDate.isBefore(fromDate)) {
      return const Left('To Date cannot be earlier than From Date');
    }
    try {
      final rowsResult = await _repository.getProductionReport(
        fromDate: fromDate,
        toDate: toDate,
        search: search,
      );
      String? rowsError;
      rowsResult.fold((error) => rowsError = error, (_) {});
      if (rowsError != null) return Left(rowsError!);
      final rows = rowsResult.getOrElse(() => const <ProductionReportEntity>[]);
      final summaryResult = await _repository.getReportSummary(
        fromDate: fromDate,
        toDate: toDate,
        search: search,
      );
      return summaryResult.fold(
        Left.new,
        (summary) => Right(
          ProductionReportResult(
            rows: rows,
            summary: summary,
            fromDate: fromDate,
            toDate: toDate,
            search: search,
          ),
        ),
      );
    } catch (_) {
      return const Left('Unable to generate the production report');
    }
  }
}
