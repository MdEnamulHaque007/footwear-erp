/// ============================================================================
/// ফাইল: lib/domain/entities/reports/finished_goods_report_entity.dart
/// স্তর: Domain Entity | মডিউল: Reports
/// উদ্দেশ্য: Reports মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: FinishedGoodsReportEntity, FinishedGoodsReportSummary, FinishedGoodsReportResult
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
/// One line of the Finished Goods Report.
///
/// Mirrors a row of the Google Sheet `Finished Goods Report` formula. A line is
/// the distinct (poNo, article, color) triplet; the columns are derived from the
/// Issue collection (goods received into the FG warehouse = FG In) and the
/// Export collection (goods shipped out = FG Out):
///
/// * Opening Balance = Issues before `fromDate` − Exports before `fromDate`
/// * FG In           = Issues inside the date range
/// * Total           = Opening Balance + FG In
/// * FG Out          = Exports inside the date range
/// * Stock           = Total − FG Out
class FinishedGoodsReportEntity {
  const FinishedGoodsReportEntity({
    this.po = '',
    this.article = '',
    this.color = '',
    this.openingBalance = 0,
    this.fgIn = 0,
    this.fgOut = 0,
  });

  final String po;
  final String article;
  final String color;

  /// Issues before the range minus Exports before the range (the carry-in).
  final int openingBalance;

  /// Issues inside the date range.
  final int fgIn;

  /// Exports inside the date range.
  final int fgOut;

  /// Total = Opening Balance + FG In.
  int get total => openingBalance + fgIn;

  /// Stock = Total − FG Out.
  int get stock => total - fgOut;

  /// Stable identity of the line, compared case-insensitively.
  String get lineKey =>
      '${po.trim().toLowerCase()}|${article.trim().toLowerCase()}|'
      '${color.trim().toLowerCase()}';

  /// Case-insensitive match across the three visible text columns.
  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return po.toLowerCase().contains(normalized) ||
        article.toLowerCase().contains(normalized) ||
        color.toLowerCase().contains(normalized);
  }

  /// The sheet hides any row whose five numeric columns are all zero.
  bool get isNonZero =>
      openingBalance != 0 || fgIn != 0 || total != 0 || fgOut != 0 || stock != 0;
}

/// Grand-total row of the Finished Goods Report (the sheet's TOTAL line).
class FinishedGoodsReportSummary {
  const FinishedGoodsReportSummary({
    this.totalOpeningBalance = 0,
    this.totalFGIn = 0,
    this.totalTotal = 0,
    this.totalFGOut = 0,
    this.totalStock = 0,
    this.rowCount = 0,
  });

  final int totalOpeningBalance;
  final int totalFGIn;
  final int totalTotal;
  final int totalFGOut;
  final int totalStock;
  final int rowCount;

  static FinishedGoodsReportSummary fromRows(
    List<FinishedGoodsReportEntity> rows,
  ) {
    var opening = 0, fgIn = 0, total = 0, fgOut = 0, stock = 0;
    for (final row in rows) {
      opening += row.openingBalance;
      fgIn += row.fgIn;
      total += row.total;
      fgOut += row.fgOut;
      stock += row.stock;
    }
    return FinishedGoodsReportSummary(
      totalOpeningBalance: opening,
      totalFGIn: fgIn,
      totalTotal: total,
      totalFGOut: fgOut,
      totalStock: stock,
      rowCount: rows.length,
    );
  }
}

/// A generated report: the rows plus the grand total and the parameters used.
class FinishedGoodsReportResult {
  const FinishedGoodsReportResult({
    required this.rows,
    required this.summary,
    required this.fromDate,
    required this.toDate,
    this.search = '',
  });

  final List<FinishedGoodsReportEntity> rows;
  final FinishedGoodsReportSummary summary;
  final DateTime fromDate;
  final DateTime toDate;
  final String search;
}
