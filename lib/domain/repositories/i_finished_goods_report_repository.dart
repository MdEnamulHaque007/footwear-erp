/// ============================================================================
/// ফাইল: lib/domain/repositories/i_finished_goods_report_repository.dart
/// স্তর: Domain Repository Contract | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common data access-এর interface নির্ধারণ করে; implementation data layer-এ থাকে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
