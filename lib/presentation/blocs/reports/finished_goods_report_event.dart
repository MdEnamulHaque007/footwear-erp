/// ============================================================================
/// ফাইল: lib/presentation/blocs/reports/finished_goods_report_event.dart
/// স্তর: Presentation BLoC | মডিউল: Reports
/// উদ্দেশ্য: Reports screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: FinishedGoodsReportEvent, LoadFinishedGoodsReport, UpdateDateRange, UpdateSearch, RefreshReport, ClearFilters, ExportReportRequested
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/reports/finished_goods_report_entity.dart';

sealed class FinishedGoodsReportEvent {}

/// Builds the report for a date range + search query.
class LoadFinishedGoodsReport extends FinishedGoodsReportEvent {
  LoadFinishedGoodsReport({
    required this.fromDate,
    required this.toDate,
    this.search = '',
  });
  final DateTime fromDate;
  final DateTime toDate;
  final String search;
}

/// Changes the date range and regenerates.
class UpdateDateRange extends FinishedGoodsReportEvent {
  UpdateDateRange({required this.fromDate, required this.toDate});
  final DateTime fromDate;
  final DateTime toDate;
}

/// Changes the search text and regenerates.
class UpdateSearch extends FinishedGoodsReportEvent {
  UpdateSearch(this.search);
  final String search;
}

class RefreshReport extends FinishedGoodsReportEvent {}

/// Resets the filters back to the default (current month, no search).
class ClearFilters extends FinishedGoodsReportEvent {}

class ExportReportRequested extends FinishedGoodsReportEvent {
  ExportReportRequested(this.result, {required this.asPdf});
  final FinishedGoodsReportResult result;
  final bool asPdf;
}
