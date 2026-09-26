/// ============================================================================
/// ফাইল: lib/presentation/blocs/reports/finished_goods_report_state.dart
/// স্তর: Presentation BLoC | মডিউল: Reports
/// উদ্দেশ্য: Reports screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: FinishedGoodsReportState, FinishedGoodsReportInitial, FinishedGoodsReportLoading, FinishedGoodsReportLoaded, FinishedGoodsReportEmpty, FinishedGoodsReportError, FinishedGoodsReportExported
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/reports/finished_goods_report_entity.dart';

sealed class FinishedGoodsReportState {}

class FinishedGoodsReportInitial extends FinishedGoodsReportState {}

class FinishedGoodsReportLoading extends FinishedGoodsReportState {}

class FinishedGoodsReportLoaded extends FinishedGoodsReportState {
  FinishedGoodsReportLoaded(this.result);
  final FinishedGoodsReportResult result;

  List<FinishedGoodsReportEntity> get rows => result.rows;
  FinishedGoodsReportSummary get summary => result.summary;
}

/// The query succeeded but matched no lines.
class FinishedGoodsReportEmpty extends FinishedGoodsReportState {
  FinishedGoodsReportEmpty({required this.fromDate, required this.toDate});
  final DateTime fromDate;
  final DateTime toDate;
}

class FinishedGoodsReportError extends FinishedGoodsReportState {
  FinishedGoodsReportError(this.message);
  final String message;
}

/// Export finished successfully.
class FinishedGoodsReportExported extends FinishedGoodsReportState {
  FinishedGoodsReportExported(this.message);
  final String message;
}
