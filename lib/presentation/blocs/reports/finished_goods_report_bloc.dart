import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/exporters/excel_exporter.dart';
import '../../../core/utils/exporters/pdf_exporter.dart';
import '../../../domain/entities/reports/finished_goods_report_entity.dart';
import '../../../domain/usecases/reports/generate_finished_goods_report_usecase.dart';
import 'finished_goods_report_event.dart';
import 'finished_goods_report_state.dart';

class FinishedGoodsReportBloc
    extends Bloc<FinishedGoodsReportEvent, FinishedGoodsReportState> {
  FinishedGoodsReportBloc({
    required this.generate,
    ExcelExporter excelExporter = const ExcelExporter(),
    PdfExporter pdfExporter = const PdfExporter(),
  }) : _excelExporter = excelExporter,
       _pdfExporter = pdfExporter,
       super(FinishedGoodsReportInitial()) {
    // Defaults to the current month, matching the sheet's workflow.
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;

    on<LoadFinishedGoodsReport>(_onLoad);
    on<UpdateDateRange>(_onUpdateDateRange);
    on<UpdateSearch>(_onUpdateSearch);
    on<RefreshReport>(_onRefresh);
    on<ClearFilters>(_onClearFilters);
    on<ExportReportRequested>(_onExport);
  }

  Future<void> _onLoad(
    LoadFinishedGoodsReport event,
    Emitter<FinishedGoodsReportState> emit,
  ) async {
    _fromDate = event.fromDate;
    _toDate = event.toDate;
    _search = event.search;
    await _generateReport(emit);
  }

  Future<void> _onUpdateDateRange(
    UpdateDateRange event,
    Emitter<FinishedGoodsReportState> emit,
  ) async {
    _fromDate = event.fromDate;
    _toDate = event.toDate;
    await _generateReport(emit);
  }

  Future<void> _onUpdateSearch(
    UpdateSearch event,
    Emitter<FinishedGoodsReportState> emit,
  ) async {
    _search = event.search;
    await _generateReport(emit);
  }

  Future<void> _onRefresh(
    RefreshReport event,
    Emitter<FinishedGoodsReportState> emit,
  ) async {
    add(
      LoadFinishedGoodsReport(
        fromDate: _fromDate,
        toDate: _toDate,
        search: _search,
      ),
    );
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<FinishedGoodsReportState> emit,
  ) async {
    final now = DateTime.now();
    _search = '';
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
    await _generateReport(emit);
  }

  Future<void> _onExport(
    ExportReportRequested event,
    Emitter<FinishedGoodsReportState> emit,
  ) async {
    try {
      if (event.asPdf) {
        final bytes = await _pdfExporter.buildFinishedGoodsReport(event.result);
        await Printing.layoutPdf(onLayout: (_) async => bytes);
        if (emit.isDone) return;
        emit(FinishedGoodsReportExported('PDF ready to print'));
      } else {
        final bytes = _excelExporter.buildFinishedGoodsReport(event.result);
        // `Printing.sharePdf` is the one download path that works on web,
        // Android, iOS and desktop without extra platform plugins.
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'finished_goods_report.xlsx',
        );
        if (emit.isDone) return;
        emit(FinishedGoodsReportExported('Excel exported'));
      }
    } catch (_) {
      if (emit.isDone) return;
      emit(FinishedGoodsReportError('Unable to export the report'));
    }
  }

  Future<void> _generateReport(Emitter<FinishedGoodsReportState> emit) async {
    emit(FinishedGoodsReportLoading());
    final result = await generate(
      fromDate: _fromDate,
      toDate: _toDate,
      search: _search,
    );
    if (emit.isDone) return;
    String? error;
    FinishedGoodsReportResult? report;
    result.fold((message) => error = message, (value) => report = value);
    if (error != null) {
      emit(FinishedGoodsReportError(error!));
      return;
    }
    final resolved = report;
    if (resolved == null) {
      emit(FinishedGoodsReportError('Unable to generate the report'));
      return;
    }
    if (resolved.rows.isEmpty) {
      emit(FinishedGoodsReportEmpty(fromDate: _fromDate, toDate: _toDate));
      return;
    }
    emit(FinishedGoodsReportLoaded(resolved));
  }

  final GenerateFinishedGoodsReportUseCase generate;
  final ExcelExporter _excelExporter;
  final PdfExporter _pdfExporter;

  late DateTime _fromDate;
  late DateTime _toDate;
  String _search = '';
}
