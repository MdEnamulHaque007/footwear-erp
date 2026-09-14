import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/entities/reports/finished_goods_report_entity.dart';
import '../../../domain/entities/reports/production_report_entity.dart';

/// Builds the Production Report as a PDF document.
class PdfExporter {
  const PdfExporter();

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _numberFormat = NumberFormat('#,##0');

  Future<Uint8List> buildProductionReport(ProductionReportResult result) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Production Report',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Date Range: ${_dateFormat.format(result.fromDate)} '
              'to ${_dateFormat.format(result.toDate)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Generated: ${_dateFormat.format(DateTime.now())} '
              '${DateFormat('hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Company',
              'Project',
              'PO',
              'Article',
              'Color',
              'PO Qty',
              'Cutting',
              'Sewing',
              'Lasting',
            ],
            data: [
              for (final row in result.rows)
                [
                  row.company,
                  row.project,
                  row.po,
                  row.article,
                  row.color,
                  _numberFormat.format(row.poQuantity),
                  _numberFormat.format(row.cuttingQuantity),
                  _numberFormat.format(row.sewingQuantity),
                  _numberFormat.format(row.lastingQuantity),
                ],
              [
                'TOTAL',
                '',
                '',
                '',
                '',
                _numberFormat.format(result.summary.totalPOQuantity),
                _numberFormat.format(result.summary.totalCuttingQuantity),
                _numberFormat.format(result.summary.totalSewingQuantity),
                _numberFormat.format(result.summary.totalLastingQuantity),
              ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
    return document.save();
  }

  /// Builds the Finished Goods Report as a PDF document.
  Future<Uint8List> buildFinishedGoodsReport(
    FinishedGoodsReportResult result,
  ) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Finished Goods Report',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Date Range: ${_dateFormat.format(result.fromDate)} '
              'to ${_dateFormat.format(result.toDate)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Generated: ${_dateFormat.format(DateTime.now())} '
              '${DateFormat('hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: const [
              'PO',
              'Article',
              'Color',
              'Opening Balance',
              'FG In',
              'Total',
              'FG Out',
              'Stock',
            ],
            data: [
              for (final row in result.rows)
                [
                  row.po,
                  row.article,
                  row.color,
                  _numberFormat.format(row.openingBalance),
                  _numberFormat.format(row.fgIn),
                  _numberFormat.format(row.total),
                  _numberFormat.format(row.fgOut),
                  _numberFormat.format(row.stock),
                ],
              [
                'TOTAL',
                '',
                '',
                _numberFormat.format(result.summary.totalOpeningBalance),
                _numberFormat.format(result.summary.totalFGIn),
                _numberFormat.format(result.summary.totalTotal),
                _numberFormat.format(result.summary.totalFGOut),
                _numberFormat.format(result.summary.totalStock),
              ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
    return document.save();
  }
}
