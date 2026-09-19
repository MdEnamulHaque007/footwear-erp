/// A distinct `article` + `color` pair read from the Sewing entries of a PO.
///
/// Used to drive the Production form's Article → Color cascading dropdowns so
/// only lines that have actually been sewn can be produced.
class SewingLine {
  const SewingLine({required this.article, required this.color});

  final String article;
  final String color;

  @override
  bool operator ==(Object other) =>
      other is SewingLine &&
      other.article.toLowerCase() == article.toLowerCase() &&
      other.color.toLowerCase() == color.toLowerCase();

  @override
  int get hashCode =>
      Object.hash(article.toLowerCase(), color.toLowerCase());
}

/// A Lasting/DIP production entry.
///
/// Production is PO-line driven: an entry records how many pieces of one
/// `poNo` + `article` + `color` line were produced on [productionDate]. Its
/// quantity is validated against the cumulative Sewing quantity completed on or
/// before that date. `poTagNo` and `quantity` remain the canonical stored
/// fields so the existing Issue chain and older Firestore records keep working.
class ProductionEntity {
  const ProductionEntity({
    this.id,
    required this.sl,
    required this.voucherNo,
    required this.productionDate,
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
    this.productionValue = 0,
    this.sewingQuantity = 0,
    this.remarks = '',
    this.source,
    this.syncStatus,
    this.createdAt,
    this.updatedAt,
  }) : tagNo = tagNo.isNotEmpty ? tagNo : (poTagNo ?? '');

  final String? id;
  final int sl;
  final String voucherNo;
  final DateTime productionDate;

  /// PO tag. Kept as the identity used by the Issue module and older records.
  String get poTagNo => tagNo;

  /// Legacy alias of the produced quantity (== [quantity]).
  final int quantity;

  final String entryPerson;
  final String poNo;

  /// Explicit tag column, defaults to [poTagNo] when read from legacy records.
  final String tagNo;
  final String company;
  final String project;
  final String article;
  final String color;
  final String factoryName;

  /// Unit price taken from the PO line, used to auto-calculate
  /// [productionValue] (Quantity × Unit Price).
  final double unitPrice;

  /// Auto-calculated value persisted for reporting.
  final double productionValue;

  /// Cumulative Sewing quantity completed on or before [productionDate].
  final int sewingQuantity;

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

