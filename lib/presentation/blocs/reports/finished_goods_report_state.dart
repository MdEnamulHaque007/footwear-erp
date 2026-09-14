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
