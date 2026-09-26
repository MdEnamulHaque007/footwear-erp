/// ============================================================================
/// ফাইল: lib/presentation/blocs/reports/warehouse_report_event.dart
/// স্তর: Presentation BLoC | মডিউল: Reports
/// উদ্দেশ্য: Reports screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: WarehouseReportEvent, LoadWarehouseReport, RefreshWarehouseReport, ExportWarehouseReportPdf, ExportWarehouseReportExcel
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

sealed class WarehouseReportEvent extends Equatable {
  const WarehouseReportEvent();

  @override
  List<Object?> get props => const [];
}

class LoadWarehouseReport extends WarehouseReportEvent {
  const LoadWarehouseReport({required this.fromDate, required this.toDate});

  final DateTime fromDate;
  final DateTime toDate;

  @override
  List<Object?> get props => [fromDate, toDate];
}

class RefreshWarehouseReport extends WarehouseReportEvent {
  const RefreshWarehouseReport();
}

class ExportWarehouseReportPdf extends WarehouseReportEvent {
  const ExportWarehouseReportPdf();
}

class ExportWarehouseReportExcel extends WarehouseReportEvent {
  const ExportWarehouseReportExcel();
}
