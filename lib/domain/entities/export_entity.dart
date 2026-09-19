/// A distinct `article` + `color` pair read from the Issue entries of a PO.
///
/// Used to drive the Export form's Article → Color cascading dropdowns so only
/// lines that have actually been issued can be exported.
class IssueLine {
  const IssueLine({required this.article, required this.color});

  final String article;
  final String color;

  @override
  bool operator ==(Object other) =>
      other is IssueLine &&
      other.article.toLowerCase() == article.toLowerCase() &&
      other.color.toLowerCase() == color.toLowerCase();

  @override
  int get hashCode => Object.hash(article.toLowerCase(), color.toLowerCase());
}

/// An Export (shipment) entry.
///
/// Export is PO-line driven: an entry records how many pieces of one
/// `poNo` + `article` + `color` line were exported on [exportDate]. Its quantity
/// is validated against the cumulative Issue quantity completed on or before
/// that date. `tagNo` is the single source of truth; `poTagNo` is only a
/// legacy alias retained for backward compatibility.
class ExportEntity {
  const ExportEntity({
    this.id,
    required this.sl,
    required this.voucherNo,
    required this.exportDate,
    String? poTagNo,
    required this.quantity,
    required this.entryPerson,
    this.poNo = '',
    String tagNo = '',
    this.company = '',
    this.project = '',
    this.article = '',
    this.color = '',
    this.factoryName = '',
    this.unitPrice = 0,
    this.exportValue = 0,
    this.issueQuantity = 0,
    this.remarks = '',
    this.source,
    this.syncStatus,
    this.createdAt,
    this.updatedAt,
  }) : tagNo = tagNo.isNotEmpty ? tagNo : (poTagNo ?? '');

  final String? id;
  final int sl;
  final String voucherNo;
  final DateTime exportDate;

  /// Legacy alias of [tagNo]. Always identical to [tagNo].
  String get poTagNo => tagNo;

  /// Legacy alias of the exported quantity (== [quantity]).
  final int quantity;

  final String entryPerson;
  final String poNo;
  final String tagNo;
  final String company;
  final String project;
  final String article;
  final String color;
  final String factoryName;

  /// Unit price taken from the PO line, used to auto-calculate [exportValue].
  final double unitPrice;

  /// Auto-calculated value persisted for reporting (Quantity × Unit Price).
  final double exportValue;

  /// Cumulative Issue quantity completed on or before [exportDate].
  final int issueQuantity;

  final String remarks;

  /// Origin of the record: `manual` (app form) or `google_sheets` (import).
  final String? source;

  /// Sync state of imported records, e.g. `synced`.
  final String? syncStatus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Tag shown in tables: [tagNo] with a [poTagNo] fallback.
  String get effectiveTagNo => tagNo.isNotEmpty ? tagNo : poTagNo;
}
