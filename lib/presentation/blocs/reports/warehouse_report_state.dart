/// ============================================================================
/// ফাইল: lib/presentation/blocs/reports/warehouse_report_state.dart
/// স্তর: Presentation BLoC | মডিউল: Reports
/// উদ্দেশ্য: Reports screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: WarehouseReportState, WarehouseReportInitial, WarehouseReportLoading, WarehouseReportLoaded, WarehouseReportError, WarehouseReportExported
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

import '../../../domain/entities/reports/warehouse_report_entity.dart';

sealed class WarehouseReportState extends Equatable {
  const WarehouseReportState();

  @override
  List<Object?> get props => const [];
}

class WarehouseReportInitial extends WarehouseReportState {
  const WarehouseReportInitial();
}

class WarehouseReportLoading extends WarehouseReportState {
  const WarehouseReportLoading();
}

class WarehouseReportLoaded extends WarehouseReportState {
  const WarehouseReportLoaded(this.result);

  final WarehouseReportResult result;

  @override
  List<Object?> get props => [result];
}

class WarehouseReportError extends WarehouseReportState {
  const WarehouseReportError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class WarehouseReportExported extends WarehouseReportState {
  const WarehouseReportExported(this.message, this.result);

  final String message;
  final WarehouseReportResult result;

  @override
  List<Object?> get props => [message, result];
}
