import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/domain/entities/reports/finished_goods_report_entity.dart';

/// One source movement: a line plus the date it happened and its quantity.
class _Movement {
  const _Movement(this.po, this.article, this.color, this.date, this.qty);
  final String po;
  final String article;
  final String color;
  final DateTime date;
  final int qty;
}

/// In-memory stand-in for the four Firestore slices the repository reads.
///
/// Mirrors `FinishedGoodsReportRepository._buildRows`: issues are FG In, exports
/// are FG Out, and the opening balance is everything strictly before `from`.
class _FakeReportSource {
  _FakeReportSource(this.issues, this.exports);
  final List<_Movement> issues;
  final List<_Movement> exports;

  /// Sums [movements] for the line in [sample] where [filter] passes.
  static int _sum(
    List<_Movement> movements,
    _Movement sample,
    bool Function(_Movement) filter,
  ) {
    var total = 0;
    for (final m in movements) {
      if (!filter(m)) continue;
      final same =
          m.po.toLowerCase() == sample.po.toLowerCase() &&
          m.article.toLowerCase() == sample.article.toLowerCase() &&
          m.color.toLowerCase() == sample.color.toLowerCase();
      if (same) total += m.qty;
    }
    return total;
  }

  List<FinishedGoodsReportEntity> build({
    required DateTime fromDate,
    required DateTime toDate,
    String search = '',
  }) {
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final to = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999);

    bool inRange(_Movement m) => !m.date.isBefore(from) && !m.date.isAfter(to);
    bool before(_Movement m) => m.date.isBefore(from);

    final keys = <String, _Movement>{};
    for (final m in [...issues, ...exports]) {
      keys.putIfAbsent(
        '${m.po.toLowerCase()}|${m.article.toLowerCase()}|'
        '${m.color.toLowerCase()}',
        () => m,
      );
    }

    final rows = <FinishedGoodsReportEntity>[];
    for (final sample in keys.values) {
      final row = FinishedGoodsReportEntity(
        po: sample.po,
        article: sample.article,
        color: sample.color,
        openingBalance:
            _sum(issues, sample, before) - _sum(exports, sample, before),
        fgIn: _sum(issues, sample, inRange),
        fgOut: _sum(exports, sample, inRange),
      );
      if (!row.isNonZero) continue;
      if (!row.matches(search)) continue;
      rows.add(row);
    }
    rows.sort((a, b) {
      final byPo = a.po.toLowerCase().compareTo(b.po.toLowerCase());
      if (byPo != 0) return byPo;
      final byArticle = a.article.toLowerCase().compareTo(
        b.article.toLowerCase(),
      );
      if (byArticle != 0) return byArticle;
      return a.color.toLowerCase().compareTo(b.color.toLowerCase());
    });
    return rows;
  }
}

void main() {
  final from = DateTime(2026, 8, 1);
  final to = DateTime(2026, 8, 31);
  const po = 'E23031';
  const article = 'RED23BA008';
  const color = 'WHITE/RED';

  group('FinishedGoodsReportEntity column math', () {
    test('opening balance = issue before - export before', () {
      final source = _FakeReportSource([
        _Movement(po, article, color, DateTime(2026, 7, 10), 100),
      ], [
        _Movement(po, article, color, DateTime(2026, 7, 20), 30),
      ]);
      final rows = source.build(fromDate: from, toDate: to);
      expect(rows.single.openingBalance, 70);
    });

    test('opening balance goes negative when more shipped than received', () {
      final source = _FakeReportSource([
        _Movement(po, article, color, DateTime(2026, 7, 10), 10),
      ], [
        _Movement(po, article, color, DateTime(2026, 7, 20), 40),
      ]);
      final rows = source.build(fromDate: from, toDate: to);
      expect(rows.single.openingBalance, -30);
    });

    test('FG In = issues inside the range', () {
      final source = _FakeReportSource([
        _Movement(po, article, color, DateTime(2026, 8, 15), 500),
      ], []);
      expect(source.build(fromDate: from, toDate: to).single.fgIn, 500);
    });

    test('FG Out = exports inside the range', () {
      final source = _FakeReportSource([], [
        _Movement(po, article, color, DateTime(2026, 8, 15), 300),
      ]);
      expect(source.build(fromDate: from, toDate: to).single.fgOut, 300);
    });

    test('total = opening + FG In, stock = total - FG Out', () {
      final source = _FakeReportSource([
        _Movement(po, article, color, DateTime(2026, 7, 10), 100),
        _Movement(po, article, color, DateTime(2026, 8, 5), 500),
      ], [
        _Movement(po, article, color, DateTime(2026, 8, 20), 300),
      ]);
      final row = source.build(fromDate: from, toDate: to).single;
      expect(row.openingBalance, 100);
      expect(row.fgIn, 500);
      expect(row.total, 600);
      expect(row.fgOut, 300);
      expect(row.stock, 300);
    });

    test('both boundary dates fall inside the range', () {
      final source = _FakeReportSource([
        _Movement(po, article, color, DateTime(2026, 8, 1), 10),
        _Movement(po, article, color, DateTime(2026, 8, 31), 20),
      ], []);
      final row = source.build(fromDate: from, toDate: to).single;
      expect(row.fgIn, 30);
      expect(row.openingBalance, 0);
    });
  });

  group('FinishedGoodsReportSummary grand total', () {
    test('sums each column independently', () {
      final source = _FakeReportSource([
        _Movement('E23031', 'A', 'X', DateTime(2026, 7, 1), 100),
        _Movement('E24020', 'B', 'Y', DateTime(2026, 8, 5), 200),
      ], [
        _Movement('E23031', 'A', 'X', DateTime(2026, 8, 10), 40),
      ]);
      final summary = FinishedGoodsReportSummary.fromRows(
        source.build(fromDate: from, toDate: to),
      );
      expect(summary.rowCount, 2);
      expect(summary.totalOpeningBalance, 100);
      expect(summary.totalFGIn, 200);
      expect(summary.totalTotal, 300);
      expect(summary.totalFGOut, 40);
      expect(summary.totalStock, 260);
    });

    test('an empty report totals to zero', () {
      final summary = FinishedGoodsReportSummary.fromRows(const []);
      expect(summary.rowCount, 0);
      expect(summary.totalOpeningBalance, 0);
      expect(summary.totalFGIn, 0);
      expect(summary.totalTotal, 0);
      expect(summary.totalFGOut, 0);
      expect(summary.totalStock, 0);
    });
  });

  group('lineKey and matches', () {
    test('lineKey is case-insensitive and trims whitespace', () {
      const a = FinishedGoodsReportEntity(
        po: ' E23031 ',
        article: 'Red23BA008',
        color: 'White/Red',
      );
      const b = FinishedGoodsReportEntity(
        po: 'e23031',
        article: 'RED23BA008',
        color: 'WHITE/RED',
      );
      expect(a.lineKey, b.lineKey);
    });

    test('matches searches PO, article and color case-insensitively', () {
      const row = FinishedGoodsReportEntity(
        po: 'E24020',
        article: 'RSO4253',
        color: 'BLUE/GREY',
      );
      expect(row.matches('e24020'), isTrue);
      expect(row.matches('rso4253'), isTrue);
      expect(row.matches('blue/grey'), isTrue);
      expect(row.matches('nope'), isFalse);
      expect(row.matches(''), isTrue);
    });

    test('search filters the built rows', () {
      final source = _FakeReportSource([
        _Movement('E24020', 'RSO4253', 'BLUE/GREY', DateTime(2026, 8, 5), 10),
        _Movement('E24030', 'RSO4403', 'Black', DateTime(2026, 8, 5), 10),
      ], []);
      expect(source.build(fromDate: from, toDate: to, search: 'NOPE'), isEmpty);
      final filtered = source.build(
        fromDate: from,
        toDate: to,
        search: 'rso4403',
      );
      expect(filtered.single.po, 'E24030');
    });
  });

  group('non-zero filter and sorting', () {
    test('fully zeroed lines are hidden', () {
      final source = _FakeReportSource([
        _Movement('E23031', 'A', 'X', DateTime(2026, 7, 1), 100),
      ], [
        _Movement('E23031', 'A', 'X', DateTime(2026, 7, 15), 100),
      ]);
      // Opening nets to zero and nothing moved in the range.
      expect(source.build(fromDate: from, toDate: to), isEmpty);
    });

    test('a line whose opening nets to zero but moved in range is kept', () {
      final source = _FakeReportSource([
        _Movement('E23031', 'A', 'X', DateTime(2026, 7, 1), 100),
        _Movement('E23031', 'A', 'X', DateTime(2026, 8, 5), 50),
      ], [
        _Movement('E23031', 'A', 'X', DateTime(2026, 7, 15), 100),
      ]);
      final row = source.build(fromDate: from, toDate: to).single;
      expect(row.openingBalance, 0);
      expect(row.fgIn, 50);
      expect(row.stock, 50);
    });

    test('rows sort by PO then Article then Color', () {
      final source = _FakeReportSource([
        _Movement('E24020', 'B', 'Y', DateTime(2026, 8, 5), 10),
        _Movement('E23031', 'Z', 'X', DateTime(2026, 8, 5), 10),
        _Movement('E24020', 'A', 'Y', DateTime(2026, 8, 5), 10),
        _Movement('E24020', 'A', 'A', DateTime(2026, 8, 5), 10),
      ], []);
      final rows = source.build(fromDate: from, toDate: to);
      expect(rows.map((r) => '${r.po}/${r.article}/${r.color}').toList(), [
        'E23031/Z/X',
        'E24020/A/A',
        'E24020/A/Y',
        'E24020/B/Y',
      ]);
    });
  });
}
