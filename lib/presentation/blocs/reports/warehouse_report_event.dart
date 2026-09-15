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
