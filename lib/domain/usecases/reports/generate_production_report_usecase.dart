/// ============================================================================
/// ফাইল: lib/domain/usecases/reports/generate_production_report_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GenerateProductionReportUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
