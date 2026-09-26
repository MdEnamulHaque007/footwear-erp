/// ============================================================================
/// ফাইল: lib/domain/repositories/i_production_report_repository.dart
/// স্তর: Domain Repository Contract | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting data access-এর interface নির্ধারণ করে; implementation data layer-এ থাকে।
/// প্রধান অংশ: top-level configuration ও helper declarations
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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
