import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/issue_entity.dart';

class IssueModel extends IssueEntity {
  const IssueModel({
    super.id,
    required super.sl,
    required super.voucherNo,
    required super.issueDate,
    required super.poTagNo,
    required super.quantity,
    required super.entryPerson,
    super.poNo,
    super.tagNo,
    super.company,
    super.project,
    super.article,
    super.color,
    super.factoryName,
    super.unitPrice,
    super.issueValue,
    super.productionQuantity,
    super.availableQuantity,
    super.remarks,
    super.source,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory IssueModel.fromEntity(IssueEntity e) => IssueModel(
    id: e.id,
    sl: e.sl,
    voucherNo: e.voucherNo,
    issueDate: e.issueDate,
    poTagNo: e.poTagNo,
    quantity: e.quantity,
    entryPerson: e.entryPerson,
    poNo: e.poNo,
    tagNo: e.tagNo,
    company: e.company,
    project: e.project,
    article: e.article,
    color: e.color,
    factoryName: e.factoryName,
    unitPrice: e.unitPrice,
    issueValue: e.issueValue,
    productionQuantity: e.productionQuantity,
    availableQuantity: e.availableQuantity,
    remarks: e.remarks,
    source: e.source,
    syncStatus: e.syncStatus,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  /// Reads a Firestore document defensively: legacy records may store numbers as
  /// strings, dates as `Timestamp` / `DateTime` / ISO strings and may only carry
  /// the legacy `poTagNo` + `quantity` fields.
  factory IssueModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? {};
    final poTagNo = _string(d['poTagNo']);
    final quantity = _int(d['quantity'] ?? d['issueQuantity']);
    return IssueModel(
      id: s.id,
      sl: _int(d['sl']),
      voucherNo: _string(d['voucherNo']),
      issueDate: _date(d['issueDate']) ?? DateTime.now(),
      poTagNo: poTagNo,
      quantity: quantity,
      entryPerson: _string(d['entryPerson']),
      poNo: _string(d['poNo']),
      tagNo: _string(d['tagNo'] ?? poTagNo),
      company: _string(d['company']),
      project: _string(d['project']),
      article: _string(d['article']),
      color: _string(d['color']),
      factoryName: _string(d['factoryName']),
      unitPrice: _double(d['unitPrice']),
      issueValue: _double(d['issueValue']),
      productionQuantity: _int(d['productionQuantity']),
      availableQuantity: _int(d['availableQuantity']),
      remarks: _string(d['remarks']),
      source: d['source'] as String?,
      syncStatus: d['syncStatus'] as String?,
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sl': sl,
    'voucherNo': voucherNo,
    'issueDate': Timestamp.fromDate(issueDate),
    'poTagNo': poTagNo,
    'tagNo': effectiveTagNo,
    'quantity': quantity,
    'issueQuantity': quantity,
    'entryPerson': entryPerson,
    'poNo': poNo,
    'company': company,
    'project': project,
    'article': article,
    'color': color,
    'factoryName': factoryName,
    'unitPrice': unitPrice,
    'issueValue': issueValue,
    'productionQuantity': productionQuantity,
    'availableQuantity': availableQuantity,
    'remarks': remarks,
    'createdAt': createdAt == null
        ? Timestamp.now()
        : Timestamp.fromDate(createdAt!),
    'updatedAt': Timestamp.now(),
    'source': source ?? 'manual',
    'syncStatus': syncStatus ?? 'synced',
  };

  IssueEntity toEntity() => IssueEntity(
    id: id,
    sl: sl,
    voucherNo: voucherNo,
    issueDate: issueDate,
    poTagNo: poTagNo,
    quantity: quantity,
    entryPerson: entryPerson,
    poNo: poNo,
    tagNo: tagNo,
    company: company,
    project: project,
    article: article,
    color: color,
    factoryName: factoryName,
    unitPrice: unitPrice,
    issueValue: issueValue,
    productionQuantity: productionQuantity,
    availableQuantity: availableQuantity,
    remarks: remarks,
    source: source,
    syncStatus: syncStatus,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static int _int(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  static double _double(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().trim() ?? '') ?? 0;

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
