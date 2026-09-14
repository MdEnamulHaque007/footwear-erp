import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/entities/reports/production_report_entity.dart';

ProductionReportEntity _row({
  String company = 'REDTAPE',
  String project = 'UPTOP',
  String po = 'E26016',
  String article = 'RSO4862',
  String color = 'GREY',
  int poQuantity = 0,
  int cutting = 0,
  int sewing = 0,
  int lasting = 0,
}) => ProductionReportEntity(
  company: company,
  project: project,
  po: po,
  article: article,
  color: color,
  poQuantity: poQuantity,
  cuttingQuantity: cutting,
  sewingQuantity: sewing,
  lastingQuantity: lasting,
);

void main() {
  group('ProductionReportSummary', () {
    test('sums each quantity column independently', () {
      final summary = ProductionReportSummary.fromRows([
        _row(poQuantity: 12000, sewing: 235),
        _row(article: 'RSO4863', poQuantity: 12000, sewing: 230),
        _row(
          article: 'RSO4864',
          poQuantity: 5000,
          cutting: 5000,
          sewing: 4800,
          lasting: 4700,
        ),
      ]);
      expect(summary.totalPOQuantity, 29000);
      expect(summary.totalCuttingQuantity, 5000);
      expect(summary.totalSewingQuantity, 5265);
      expect(summary.totalLastingQuantity, 4700);
      expect(summary.rowCount, 3);
    });

    test('an empty report totals to zero with no rows', () {
      final summary = ProductionReportSummary.fromRows(const []);
      expect(summary.totalPOQuantity, 0);
      expect(summary.totalCuttingQuantity, 0);
      expect(summary.totalSewingQuantity, 0);
      expect(summary.totalLastingQuantity, 0);
      expect(summary.rowCount, 0);
    });

    test('grand total equals the column-by-column sum', () {
      final rows = [
        _row(poQuantity: 100, cutting: 10, sewing: 5, lasting: 1),
        _row(article: 'A2', poQuantity: 200, cutting: 20, sewing: 15, lasting: 2),
      ];
      final summary = ProductionReportSummary.fromRows(rows);
      expect(summary.totalPOQuantity, 300);
      expect(summary.totalCuttingQuantity, 30);
      expect(summary.totalSewingQuantity, 20);
      expect(summary.totalLastingQuantity, 3);
    });
  });

  group('ProductionReportEntity.lineKey', () {
    test('is stable across casing and surrounding whitespace', () {
      final a = _row(po: 'E26016', article: 'RSO4862', color: 'GREY');
      final b = _row(po: ' e26016 ', article: 'rso4862', color: 'grey ');
      expect(a.lineKey, b.lineKey);
    });

    test('differs when the color differs', () {
      final a = _row(color: 'GREY');
      final b = _row(color: 'BLUE');
      expect(a.lineKey, isNot(b.lineKey));
    });
  });

  group('ProductionReportEntity.matches (search)', () {
    test('an empty query matches every row', () {
      expect(_row().matches(''), isTrue);
      expect(_row().matches('   '), isTrue);
    });

    test('matches case-insensitively on company', () {
      expect(_row(company: 'REDTAPE').matches('redtape'), isTrue);
    });

    test('matches on project, PO, article and color', () {
      final row = _row(
        project: 'UPTOP',
        po: 'E26016',
        article: 'RSO4862',
        color: 'GREY',
      );
      expect(row.matches('uptop'), isTrue);
      expect(row.matches('e26016'), isTrue);
      expect(row.matches('rso4862'), isTrue);
      expect(row.matches('grey'), isTrue);
    });

    test('rejects a query that appears in no field', () {
      expect(_row().matches('zzz-not-present'), isFalse);
    });
  });
}
