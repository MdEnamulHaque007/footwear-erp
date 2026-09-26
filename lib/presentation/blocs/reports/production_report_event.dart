/// ============================================================================
/// ফাইল: lib/presentation/blocs/reports/production_report_event.dart
/// স্তর: Presentation BLoC | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: ProductionReportEvent, LoadProductionReport, UpdateDateRange, UpdateSearch, RefreshReport, ClearFilters, ExportReportRequested
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/reports/production_report_entity.dart';

sealed class ProductionReportEvent {}

/// Builds the report for a date range + search query.
class LoadProductionReport extends ProductionReportEvent {
  LoadProductionReport({
    required this.fromDate,
    required this.toDate,
    this.search = '',
  });
  final DateTime fromDate;
  final DateTime toDate;
  final String search;
}

/// Changes the date range and regenerates.
class UpdateDateRange extends ProductionReportEvent {
  UpdateDateRange({required this.fromDate, required this.toDate});
  final DateTime fromDate;
  final DateTime toDate;
}

/// Changes the search text and regenerates.
class UpdateSearch extends ProductionReportEvent {
  UpdateSearch(this.search);
  final String search;
}

class RefreshReport extends ProductionReportEvent {}

/// Resets the filters back to the default (current month, no search).
class ClearFilters extends ProductionReportEvent {}

class ExportReportRequested extends ProductionReportEvent {
  ExportReportRequested(this.result, {required this.asPdf});
  final ProductionReportResult result;
  final bool asPdf;
}
