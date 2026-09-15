class WarehouseReportRow {
  const WarehouseReportRow({
    required this.company,
    required this.project,
    required this.poNo,
    required this.article,
    required this.color,
    required this.poQuantity,
    required this.cuttingQuantity,
    required this.sewingQuantity,
    required this.lastingQuantity,
  });

  final String company;
  final String project;
  final String poNo;
  final String article;
  final String color;
  final int poQuantity;
  final int cuttingQuantity;
  final int sewingQuantity;
  final int lastingQuantity;

  String get lineKey =>
      '${company.trim()}|${project.trim()}|${poNo.trim()}|'
      '${article.trim()}|${color.trim()}'.toLowerCase();

  WarehouseReportRow copyWith({
    String? company,
    String? project,
    String? poNo,
    String? article,
    String? color,
    int? poQuantity,
    int? cuttingQuantity,
    int? sewingQuantity,
    int? lastingQuantity,
  }) => WarehouseReportRow(
    company: company ?? this.company,
    project: project ?? this.project,
    poNo: poNo ?? this.poNo,
    article: article ?? this.article,
    color: color ?? this.color,
    poQuantity: poQuantity ?? this.poQuantity,
    cuttingQuantity: cuttingQuantity ?? this.cuttingQuantity,
    sewingQuantity: sewingQuantity ?? this.sewingQuantity,
    lastingQuantity: lastingQuantity ?? this.lastingQuantity,
  );
}

class WarehouseReportSummary {
  const WarehouseReportSummary({
    required this.totalPoQuantity,
    required this.totalCuttingQuantity,
    required this.totalSewingQuantity,
    required this.totalLastingQuantity,
  });

  final int totalPoQuantity;
  final int totalCuttingQuantity;
  final int totalSewingQuantity;
  final int totalLastingQuantity;

  factory WarehouseReportSummary.fromRows(List<WarehouseReportRow> rows) {
    var po = 0;
    var cutting = 0;
    var sewing = 0;
    var lasting = 0;
    for (final row in rows) {
      po += row.poQuantity;
      cutting += row.cuttingQuantity;
      sewing += row.sewingQuantity;
      lasting += row.lastingQuantity;
    }
    return WarehouseReportSummary(
      totalPoQuantity: po,
      totalCuttingQuantity: cutting,
      totalSewingQuantity: sewing,
      totalLastingQuantity: lasting,
    );
  }
}

class WarehouseReportResult {
  const WarehouseReportResult({
    required this.rows,
    required this.summary,
    required this.fromDate,
    required this.toDate,
  });

  final List<WarehouseReportRow> rows;
  final WarehouseReportSummary summary;
  final DateTime fromDate;
  final DateTime toDate;
}
