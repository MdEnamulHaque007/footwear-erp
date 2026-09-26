/// ============================================================================
/// ফাইল: lib/domain/entities/cutting_entity.dart
/// স্তর: Domain Entity | মডিউল: Cutting
/// উদ্দেশ্য: Cutting মডিউলের framework-independent business data ও হিসাবযোগ্য property সংজ্ঞায়িত করে।
/// প্রধান অংশ: CuttingLine, CuttingEntity
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
/// A distinct `article` + `color` pair read from the PO line items.
///
/// Keeps the Cutting form's Article → Color cascading in sync with the
/// Production/Issue/Export modules, which already use a typed line value.
class CuttingLine {
  const CuttingLine({required this.article, required this.color});

  final String article;
  final String color;

  @override
  bool operator ==(Object other) =>
      other is CuttingLine &&
      other.article.toLowerCase() == article.toLowerCase() &&
      other.color.toLowerCase() == color.toLowerCase();

  @override
  int get hashCode => Object.hash(article.toLowerCase(), color.toLowerCase());
}

/// A Cutting (fabric cutting) entry.
///
/// PO-line driven: an entry records how many pieces of one
/// `poNo` + `article` + `color` line were cut on [cuttingDate]. `tagNo` is the
/// single source of truth; `poTagNo` is retained only as a legacy alias.
class CuttingEntity {
  const CuttingEntity({
    this.id,
    required this.voucherNo,
    required this.cuttingDate,
    this.poNo = '',
    String tagNo = '',
    this.company = '',
    this.project = '',
    this.article = '',
    this.color = '',
    this.poQuantity = 0,
    this.cuttingQuantity = 0,
    String? poTagNo,
    int? quantity,
    this.factoryName = '',
    required this.entryPerson,
    this.remarks = '',
    this.source,
    this.syncStatus,
    this.createdAt,
    this.updatedAt,
  }) : tagNo = tagNo.isNotEmpty ? tagNo : (poTagNo ?? ''),
       quantity = quantity ?? cuttingQuantity;

  final String? id;
  final String voucherNo;
  final DateTime cuttingDate;
  final String poNo;

  /// PO tag, auto-filled from the Purchase Order.
  final String tagNo;
  final String company;
  final String project;
  final String article;
  final String color;

  /// Ordered quantity of the PO line this cutting belongs to.
  final int poQuantity;

  /// The cutting quantity entered in this entry.
  final int cuttingQuantity;

  /// Legacy PO tag alias. Always identical to [tagNo].
  String get poTagNo => tagNo;

  /// Legacy alias of [cuttingQuantity].
  final int quantity;

  final String factoryName;
  final String entryPerson;
  final String remarks;

  /// Origin of the record: `manual` (app form) or `google_sheets` (import).
  final String? source;

  /// Sync state of imported records, e.g. `synced`.
  final String? syncStatus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Tag shown in tables: [tagNo] with a [poTagNo] fallback.
  String get effectiveTagNo => tagNo.isNotEmpty ? tagNo : poTagNo;

  /// Returns a copy with the provided fields replaced.
  CuttingEntity copyWith({
    String? id,
    String? voucherNo,
    DateTime? cuttingDate,
    String? poNo,
    String? tagNo,
    String? company,
    String? project,
    String? article,
    String? color,
    int? poQuantity,
    int? cuttingQuantity,
    int? quantity,
    String? factoryName,
    String? entryPerson,
    String? remarks,
    String? source,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CuttingEntity(
    id: id ?? this.id,
    voucherNo: voucherNo ?? this.voucherNo,
    cuttingDate: cuttingDate ?? this.cuttingDate,
    poNo: poNo ?? this.poNo,
    tagNo: tagNo ?? this.tagNo,
    company: company ?? this.company,
    project: project ?? this.project,
    article: article ?? this.article,
    color: color ?? this.color,
    poQuantity: poQuantity ?? this.poQuantity,
    cuttingQuantity: cuttingQuantity ?? this.cuttingQuantity,
    poTagNo: this.poTagNo,
    quantity: quantity ?? this.quantity,
    factoryName: factoryName ?? this.factoryName,
    entryPerson: entryPerson ?? this.entryPerson,
    remarks: remarks ?? this.remarks,
    source: source ?? this.source,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

