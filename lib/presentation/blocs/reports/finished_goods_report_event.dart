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
