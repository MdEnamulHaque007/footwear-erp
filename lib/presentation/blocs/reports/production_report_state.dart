/// ============================================================================
/// ফাইল: lib/presentation/blocs/reports/production_report_state.dart
/// স্তর: Presentation BLoC | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: ProductionReportState, ProductionReportInitial, ProductionReportLoading, ProductionReportLoaded, ProductionReportEmpty, ProductionReportError, ProductionReportExported
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../../domain/entities/reports/production_report_entity.dart';

sealed class ProductionReportState {}

class ProductionReportInitial extends ProductionReportState {}

class ProductionReportLoading extends ProductionReportState {}

class ProductionReportLoaded extends ProductionReportState {
  ProductionReportLoaded(this.result);
  final ProductionReportResult result;

  List<ProductionReportEntity> get rows => result.rows;
  ProductionReportSummary get summary => result.summary;
}

/// The query succeeded but matched no lines.
class ProductionReportEmpty extends ProductionReportState {
  ProductionReportEmpty({required this.fromDate, required this.toDate});
  final DateTime fromDate;
  final DateTime toDate;
}

class ProductionReportError extends ProductionReportState {
  ProductionReportError(this.message);
  final String message;
}

/// Export finished successfully.
class ProductionReportExported extends ProductionReportState {
  ProductionReportExported(this.message);
  final String message;
}
