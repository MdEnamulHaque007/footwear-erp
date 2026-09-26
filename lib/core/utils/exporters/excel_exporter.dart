/// ============================================================================
/// ফাইল: lib/core/utils/exporters/excel_exporter.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Excel Exporter সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: ExcelExporter
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../domain/entities/reports/finished_goods_report_entity.dart';
import '../../../domain/entities/reports/production_report_entity.dart';

/// Builds the Production Report as an `.xlsx` workbook.
///
/// Mirrors the Google Sheet layout: a header row, one row per PO line, and a
/// bold TOTAL row summing the four quantity columns.
class ExcelExporter {
  const ExcelExporter();

  static const _headers = [
    'Company',
    'Project',
    'PO',
    'Article',
    'Color',
    'PO Qty',
    'Cutting',
    'Sewing',
    'Lasting',
  ];

  /// Builds the workbook bytes. [sheetName] defaults to the first sheet.
  Uint8List buildProductionReport(
    ProductionReportResult result, {
    String sheetName = 'Production Report',
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];

    // Header row (bold).
    sheet.appendRow(_headers);
    for (var col = 0; col < _headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = CellStyle(bold: true);
    }

    for (final row in result.rows) {
      sheet.appendRow([
        row.company,
        row.project,
        row.po,
        row.article,
        row.color,
        row.poQuantity,
        row.cuttingQuantity,
        row.sewingQuantity,
        row.lastingQuantity,
      ]);
    }

    final summary = result.summary;
    sheet.appendRow([
      'TOTAL',
      '',
      '',
      '',
      '',
      summary.totalPOQuantity,
      summary.totalCuttingQuantity,
      summary.totalSewingQuantity,
      summary.totalLastingQuantity,
    ]);
    final totalRowIndex = sheet.maxRows - 1;
    for (var col = 0; col < _headers.length; col++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: totalRowIndex),
          )
          .cellStyle = CellStyle(bold: true);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? const []);
  }

  static const _fgHeaders = [
    'PO',
    'Article',
    'Color',
    'Opening Balance',
    'FG In',
    'Total',
    'FG Out',
    'Stock',
  ];

  /// Builds the Finished Goods Report workbook.
  ///
  /// Mirrors the Google Sheet layout: one row per PO line plus a bold TOTAL row
  /// summing the five numeric columns.
  Uint8List buildFinishedGoodsReport(
    FinishedGoodsReportResult result, {
    String sheetName = 'Finished Goods Report',
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];

    sheet.appendRow(_fgHeaders);
    for (var col = 0; col < _fgHeaders.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .cellStyle = CellStyle(bold: true);
    }

    for (final row in result.rows) {
      sheet.appendRow([
        row.po,
        row.article,
        row.color,
        row.openingBalance,
        row.fgIn,
        row.total,
        row.fgOut,
        row.stock,
      ]);
    }

    final summary = result.summary;
    sheet.appendRow([
      'TOTAL',
      '',
      '',
      summary.totalOpeningBalance,
      summary.totalFGIn,
      summary.totalTotal,
      summary.totalFGOut,
      summary.totalStock,
    ]);
    final totalRowIndex = sheet.maxRows - 1;
    for (var col = 0; col < _fgHeaders.length; col++) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: totalRowIndex,
            ),
          )
          .cellStyle = CellStyle(bold: true);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? const []);
  }
}

