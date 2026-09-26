/// ============================================================================
/// ফাইল: lib/presentation/blocs/reports/production_report_bloc.dart
/// স্তর: Presentation BLoC | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: ProductionReportBloc
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/exporters/excel_exporter.dart';
import '../../../core/utils/exporters/pdf_exporter.dart';
import '../../../domain/entities/reports/production_report_entity.dart';
import '../../../domain/usecases/reports/generate_production_report_usecase.dart';
import 'production_report_event.dart';
import 'production_report_state.dart';

class ProductionReportBloc
    extends Bloc<ProductionReportEvent, ProductionReportState> {
  ProductionReportBloc({
    required this.generate,
    ExcelExporter excelExporter = const ExcelExporter(),
    PdfExporter pdfExporter = const PdfExporter(),
  }) : _excelExporter = excelExporter,
       _pdfExporter = pdfExporter,
       super(ProductionReportInitial()) {
    // Defaults to the current month, matching the sheet's workflow.
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;

    on<LoadProductionReport>(_onLoad);
    on<UpdateDateRange>(_onUpdateDateRange);
    on<UpdateSearch>(_onUpdateSearch);
    on<RefreshReport>(_onRefresh);
    on<ClearFilters>(_onClearFilters);
    on<ExportReportRequested>(_onExport);
  }

  Future<void> _onLoad(
    LoadProductionReport event,
    Emitter<ProductionReportState> emit,
  ) async {
    _fromDate = event.fromDate;
    _toDate = event.toDate;
    _search = event.search;
    await _generate(emit);
  }

  Future<void> _onUpdateDateRange(
    UpdateDateRange event,
    Emitter<ProductionReportState> emit,
  ) async {
    _fromDate = event.fromDate;
    _toDate = event.toDate;
    await _generate(emit);
  }

  Future<void> _onUpdateSearch(
    UpdateSearch event,
    Emitter<ProductionReportState> emit,
  ) async {
    _search = event.search;
    await _generate(emit);
  }

  Future<void> _onRefresh(
    RefreshReport event,
    Emitter<ProductionReportState> emit,
  ) async {
    add(LoadProductionReport(
      fromDate: _fromDate,
      toDate: _toDate,
      search: _search,
    ));
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<ProductionReportState> emit,
  ) async {
    final now = DateTime.now();
    _search = '';
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
    await _generate(emit);
  }

  Future<void> _onExport(
    ExportReportRequested event,
    Emitter<ProductionReportState> emit,
  ) async {
    try {
      if (event.asPdf) {
        final bytes = await _pdfExporter.buildProductionReport(event.result);
        await Printing.layoutPdf(onLayout: (_) async => bytes);
        if (emit.isDone) return;
        emit(ProductionReportExported('PDF ready to print'));
      } else {
        final bytes = _excelExporter.buildProductionReport(event.result);
        // `Printing.sharePdf` is the one download path that works on web,
        // Android, iOS and desktop without extra platform plugins.
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'production_report.xlsx',
        );
        if (emit.isDone) return;
        emit(ProductionReportExported('Excel exported'));
      }
    } catch (_) {
      if (emit.isDone) return;
      emit(ProductionReportError('Unable to export the report'));
    }
  }

  Future<void> _generate(Emitter<ProductionReportState> emit) async {
    emit(ProductionReportLoading());
    final result = await generate(
      fromDate: _fromDate,
      toDate: _toDate,
      search: _search,
    );
    if (emit.isDone) return;
    String? error;
    ProductionReportResult? report;
    result.fold((message) => error = message, (value) => report = value);
    if (error != null) {
      emit(ProductionReportError(error!));
      return;
    }
    final resolved = report;
    if (resolved == null) {
      emit(ProductionReportError('Unable to generate the report'));
      return;
    }
    if (resolved.rows.isEmpty) {
      emit(
        ProductionReportEmpty(fromDate: _fromDate, toDate: _toDate),
      );
      return;
    }
    emit(ProductionReportLoaded(resolved));
  }

  final GenerateProductionReportUseCase generate;
  final ExcelExporter _excelExporter;
  final PdfExporter _pdfExporter;

  late DateTime _fromDate;
  late DateTime _toDate;
  String _search = '';
}
