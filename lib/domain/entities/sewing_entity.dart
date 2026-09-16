/// A sewing entry.
///
/// Sewing is PO-driven: an entry is tied to a PO line
/// (`poNo` + `article` + `color`) and its quantity is validated against the
/// cumulative Cutting quantity available for that line up to [sewingDate].
/// `poTagNo` and `quantity` are kept as legacy aliases so older Firestore
/// records and existing callers (e.g. the production validation chain) keep
/// working.
class SewingEntity {
  SewingEntity({
    this.id,
    required this.sl,
    required this.voucherNo,
    required this.sewingDate,
    this.poNo = '',
    this.tagNo = '',
    this.company = '',
    this.project = '',
    this.article = '',
    this.color = '',
    this.cuttingQuantity = 0,
    this.sewingQuantity = 0,
    String? poTagNo,
    int? quantity,
    this.factoryName = '',
    required this.entryPerson,
    this.remarks = '',
    DateTime? createdAt,
    this.updatedAt,
    this.source,
    this.syncStatus,
  }) : poTagNo = poTagNo ?? tagNo,
       quantity = quantity ?? sewingQuantity,
       createdAt = createdAt ?? DateTime.now();

  final String? id;
  final int sl;
  final String voucherNo;

  /// Sewing date. Every quantity lookup is filtered on
  /// `cuttingDate <= sewingDate`.
  final DateTime sewingDate;
  final String poNo;

  /// PO tag, auto-filled from the Purchase Order.
  final String tagNo;
  final String company;
  final String project;
  final String article;
  final String color;

  /// Cumulative Cutting quantity for this PO line (Cutting records with
  /// `cuttingDate <= sewingDate`), captured at save time.
  final int cuttingQuantity;

  /// The sewing quantity entered in this entry.
  final int sewingQuantity;

  /// Legacy PO tag (kept for older records / production validation).
  final String poTagNo;

  /// Legacy alias of [sewingQuantity].
  final int quantity;

  final String factoryName;
  final String entryPerson;
  final String remarks;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Origin of the record: `manual` (app form) or `google_sheets` (import).
  final String? source;

  /// Sync state of imported records, e.g. `synced`.
  final String? syncStatus;

  /// Quantity used by legacy tables/validators: [sewingQuantity] with a
  /// [quantity] fallback for records saved before `sewingQuantity` existed.
  int get effectiveQuantity => sewingQuantity != 0 ? sewingQuantity : quantity;
}
