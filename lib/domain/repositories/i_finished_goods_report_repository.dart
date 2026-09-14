import 'package:dartz/dartz.dart';
import '../entities/reports/finished_goods_report_entity.dart';

abstract interface class IFinishedGoodsReportRepository {
  /// Builds the Finished Goods Report for [fromDate]..[toDate].
  ///
  /// Lines are discovered from the Issue (FG In) and Export (FG Out)
  /// collections — both the entries before [fromDate], which carry the opening
  /// balance, and the entries inside the range. [search] filters the result
  /// case-insensitively across poNo, article and color.
  Future<Either<String, List<FinishedGoodsReportEntity>>> getFinishedGoodsReport({
    required DateTime fromDate,
    required DateTime toDate,
    String search = '',
  });

  /// Grand totals for [fromDate]..[toDate] (the sheet's TOTAL row).
  Future<Either<String, FinishedGoodsReportSummary>> getReportSummary({
    required DateTime fromDate,
    required DateTime toDate,
    String search = '',
  });
}
