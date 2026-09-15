import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/exporters/excel_exporter.dart';
import '../../../core/utils/exporters/pdf_exporter.dart';
import '../../../domain/entities/reports/production_report_entity.dart';
import '../../../domain/entities/reports/warehouse_report_entity.dart';
import '../../../domain/usecases/reports/get_warehouse_report_usecase.dart';
import 'warehouse_report_event.dart';
import 'warehouse_report_state.dart';

class WarehouseReportBloc
    extends Bloc<WarehouseReportEvent, WarehouseReportState> {
  WarehouseReportBloc({
    required GetWarehouseReportUseCase getReport,
    ExcelExporter excelExporter = const ExcelExporter(),
    PdfExporter pdfExporter = const PdfExporter(),
  }) : _getReport = getReport,
       _excelExporter = excelExporter,
       _pdfExporter = pdfExporter,
       super(const WarehouseReportInitial()) {
    on<LoadWarehouseReport>(_onLoad);
    on<RefreshWarehouseReport>(_onRefresh);
    on<ExportWarehouseReportPdf>(_onExportPdf);
    on<ExportWarehouseReportExcel>(_onExportExcel);
  }

  final GetWarehouseReportUseCase _getReport;
  final ExcelExporter _excelExporter;
  final PdfExporter _pdfExporter;
  DateTime? _fromDate;
  DateTime? _toDate;
  WarehouseReportResult? _result;

  Future<void> _onLoad(
    LoadWarehouseReport event,
    Emitter<WarehouseReportState> emit,
  ) async {
    _fromDate = event.fromDate;
    _toDate = event.toDate;
    emit(const WarehouseReportLoading());
    final response = await _getReport(
      fromDate: event.fromDate,
      toDate: event.toDate,
    );
    if (emit.isDone) {
      return;
    }
    response.fold(
      (message) => emit(WarehouseReportError(message)),
      (result) {
        _result = result;
        emit(WarehouseReportLoaded(result));
      },
    );
  }

  Future<void> _onRefresh(
    RefreshWarehouseReport event,
    Emitter<WarehouseReportState> emit,
  ) async {
    final from = _fromDate;
    final to = _toDate;
    if (from == null || to == null) {
      return;
    }
    await _onLoad(LoadWarehouseReport(fromDate: from, toDate: to), emit);
  }

  Future<void> _onExportPdf(
    ExportWarehouseReportPdf event,
    Emitter<WarehouseReportState> emit,
  ) async {
    final report = _result;
    if (report == null) {
      return;
    }
    try {
      final bytes = await _pdfExporter.buildProductionReport(_asProduction(report));
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      if (emit.isDone) {
        return;
      }
      emit(WarehouseReportExported('PDF ready to print', report));
    } catch (_) {
      if (emit.isDone) {
        return;
      }
      emit(const WarehouseReportError('Unable to export the report'));
    }
  }

  Future<void> _onExportExcel(
    ExportWarehouseReportExcel event,
    Emitter<WarehouseReportState> emit,
  ) async {
    final report = _result;
    if (report == null) {
      return;
    }
    try {
      final bytes = _excelExporter.buildProductionReport(
        _asProduction(report),
        sheetName: 'Warehouse Report',
      );
      await Printing.sharePdf(bytes: bytes, filename: 'warehouse_report.xlsx');
      if (emit.isDone) {
        return;
      }
      emit(WarehouseReportExported('Excel exported', report));
    } catch (_) {
      if (emit.isDone) {
        return;
      }
      emit(const WarehouseReportError('Unable to export the report'));
    }
  }

  ProductionReportResult _asProduction(WarehouseReportResult report) {
    final rows = report.rows
        .map(
          (row) => ProductionReportEntity(
            company: row.company,
            project: row.project,
            po: row.poNo,
            article: row.article,
            color: row.color,
            poQuantity: row.poQuantity,
            cuttingQuantity: row.cuttingQuantity,
            sewingQuantity: row.sewingQuantity,
            lastingQuantity: row.lastingQuantity,
          ),
        )
        .toList(growable: false);
    return ProductionReportResult(
      rows: rows,
      summary: ProductionReportSummary(
        totalPOQuantity: report.summary.totalPoQuantity,
        totalCuttingQuantity: report.summary.totalCuttingQuantity,
        totalSewingQuantity: report.summary.totalSewingQuantity,
        totalLastingQuantity: report.summary.totalLastingQuantity,
        rowCount: rows.length,
      ),
      fromDate: report.fromDate,
      toDate: report.toDate,
    );
  }
}
