/// ============================================================================
/// ফাইল: lib/domain/entities/reports/production_report_entity.dart
/// স্তর: Domain Entity | মডিউল: Production/Lasting
/// উদ্দেশ্য: Production/Lasting মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: ProductionReportEntity, ProductionReportSummary, ProductionReportResult
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
/// One line of the Production Report.
///
/// Mirrors a row of the Google Sheet `Production Report` formula: the identity
/// of a PO line (company / project / PO / article / color), its ordered
/// quantity, and how much of it moved through Cutting, Sewing and Lasting
/// inside the selected date range.
class ProductionReportEntity {
  const ProductionReportEntity({
    this.company = '',
    this.project = '',
    this.po = '',
    this.article = '',
    this.color = '',
    this.poQuantity = 0,
    this.cuttingQuantity = 0,
    this.sewingQuantity = 0,
    this.lastingQuantity = 0,
  });

  final String company;
  final String project;
  final String po;
  final String article;
  final String color;

  /// Total ordered quantity for this PO line (not date-filtered).
  final int poQuantity;

  /// Cutting quantity for this line inside the date range.
  final int cuttingQuantity;

  /// Sewing quantity for this line inside the date range.
  final int sewingQuantity;

  /// Lasting (production) quantity for this line inside the date range.
  final int lastingQuantity;

  /// Stable identity of the line, used for de-duplication.
  String get lineKey =>
      '${po.trim().toLowerCase()}|${article.trim().toLowerCase()}|'
      '${color.trim().toLowerCase()}';

  /// Case-insensitive match across the five visible text columns.
  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return company.toLowerCase().contains(normalized) ||
        project.toLowerCase().contains(normalized) ||
        po.toLowerCase().contains(normalized) ||
        article.toLowerCase().contains(normalized) ||
        color.toLowerCase().contains(normalized);
  }
}

/// Grand-total row of the Production Report (the sheet's TOTAL line).
class ProductionReportSummary {
  const ProductionReportSummary({
    this.totalPOQuantity = 0,
    this.totalCuttingQuantity = 0,
    this.totalSewingQuantity = 0,
    this.totalLastingQuantity = 0,
    this.rowCount = 0,
  });

  final int totalPOQuantity;
  final int totalCuttingQuantity;
  final int totalSewingQuantity;
  final int totalLastingQuantity;
  final int rowCount;

  static ProductionReportSummary fromRows(List<ProductionReportEntity> rows) {
    var po = 0, cutting = 0, sewing = 0, lasting = 0;
    for (final row in rows) {
      po += row.poQuantity;
      cutting += row.cuttingQuantity;
      sewing += row.sewingQuantity;
      lasting += row.lastingQuantity;
    }
    return ProductionReportSummary(
      totalPOQuantity: po,
      totalCuttingQuantity: cutting,
      totalSewingQuantity: sewing,
      totalLastingQuantity: lasting,
      rowCount: rows.length,
    );
  }
}

/// A generated report: the rows plus the grand total and the parameters used.
class ProductionReportResult {
  const ProductionReportResult({
    required this.rows,
    required this.summary,
    required this.fromDate,
    required this.toDate,
    this.search = '',
  });

  final List<ProductionReportEntity> rows;
  final ProductionReportSummary summary;
  final DateTime fromDate;
  final DateTime toDate;
  final String search;
}
