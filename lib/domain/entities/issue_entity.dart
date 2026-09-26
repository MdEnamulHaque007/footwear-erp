/// ============================================================================
/// ফাইল: lib/domain/entities/issue_entity.dart
/// স্তর: Domain Entity | মডিউল: Finished Goods Issue
/// উদ্দেশ্য: Finished Goods Issue মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: ProductionLine, IssueEntity
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
/// A distinct `article` + `color` pair read from the Production entries of a PO.
///
/// Used to drive the Issue form's Article → Color cascading dropdowns so only
/// lines that have actually been produced can be issued.
class ProductionLine {
  const ProductionLine({required this.article, required this.color});

  final String article;
  final String color;

  @override
  bool operator ==(Object other) =>
      other is ProductionLine &&
      other.article.toLowerCase() == article.toLowerCase() &&
      other.color.toLowerCase() == color.toLowerCase();

  @override
  int get hashCode =>
      Object.hash(article.toLowerCase(), color.toLowerCase());
}

/// An Issue (finished goods dispatch) entry.
///
/// Issue is PO-line driven: an entry records how many pieces of one
/// `poNo` + `article` + `color` line were issued on [issueDate]. Its quantity is
/// validated against the cumulative Production quantity completed on or before
/// that date. `tagNo` is the single source of truth; `poTagNo` is only a
/// legacy alias retained for backward compatibility.
class IssueEntity {
  const IssueEntity({
    this.id,
    required this.sl,
    required this.voucherNo,
    required this.issueDate,
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
    this.issueValue = 0,
    this.productionQuantity = 0,
    this.remarks = '',
    this.source,
    this.syncStatus,
    this.createdAt,
    this.updatedAt,
  }) : tagNo = tagNo.isNotEmpty ? tagNo : (poTagNo ?? '');

  final String? id;
  final int sl;
  final String voucherNo;
  final DateTime issueDate;

  /// Legacy alias of [tagNo]. Always identical to [tagNo].
  String get poTagNo => tagNo;

  /// Legacy alias of the issued quantity (== [quantity]).
  final int quantity;

  final String entryPerson;
  final String poNo;
  final String tagNo;
  final String company;
  final String project;
  final String article;
  final String color;
  final String factoryName;

  /// Unit price taken from the PO line, used to auto-calculate [issueValue].
  final double unitPrice;

  /// Auto-calculated value persisted for reporting (Quantity × Unit Price).
  final double issueValue;

  /// Cumulative Production quantity completed on or before [issueDate].
  final int productionQuantity;

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
