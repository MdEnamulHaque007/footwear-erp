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
