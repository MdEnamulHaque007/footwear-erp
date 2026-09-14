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
