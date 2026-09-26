/// ============================================================================
/// ফাইল: lib/domain/usecases/reports/generate_finished_goods_report_usecase.dart
/// স্তর: Domain Use Case | মডিউল: Reports
/// উদ্দেশ্য: Reports মডিউলের একটি নির্দিষ্ট business operation ও validation flow পরিচালনা করে।
/// প্রধান অংশ: GenerateFinishedGoodsReportUseCase
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:dartz/dartz.dart';
import '../../entities/reports/finished_goods_report_entity.dart';
import '../../repositories/i_finished_goods_report_repository.dart';

/// Generates the Finished Goods Report: rows + grand total for one date range.
class GenerateFinishedGoodsReportUseCase {
  GenerateFinishedGoodsReportUseCase(this._repository);
  final IFinishedGoodsReportRepository _repository;

  Future<Either<String, FinishedGoodsReportResult>> call({
    required DateTime fromDate,
    required DateTime toDate,
    String search = '',
  }) async {
    if (toDate.isBefore(fromDate)) {
      return const Left('To Date cannot be earlier than From Date');
    }
    try {
      final rowsResult = await _repository.getFinishedGoodsReport(
        fromDate: fromDate,
        toDate: toDate,
        search: search,
      );
      String? rowsError;
      rowsResult.fold((error) => rowsError = error, (_) {});
      if (rowsError != null) return Left(rowsError!);
      final rows = rowsResult.getOrElse(
        () => const <FinishedGoodsReportEntity>[],
      );
      final summaryResult = await _repository.getReportSummary(
        fromDate: fromDate,
        toDate: toDate,
        search: search,
      );
      return summaryResult.fold(
        Left.new,
        (summary) => Right(
          FinishedGoodsReportResult(
            rows: rows,
            summary: summary,
            fromDate: fromDate,
            toDate: toDate,
            search: search,
          ),
        ),
      );
    } catch (_) {
      return const Left('Unable to generate the finished goods report');
    }
  }
}
