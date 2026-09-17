import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/cutting_entity.dart';

class CuttingModel extends CuttingEntity {
  const CuttingModel({
    super.id,
    required super.voucherNo,
    required super.cuttingDate,
    super.poNo,
    super.tagNo,
    super.company,
    super.project,
    super.article,
    super.color,
    super.poQuantity,
    super.cuttingQuantity,
    super.poTagNo,
    super.quantity,
    super.factoryName,
    required super.entryPerson,
    super.remarks,
    super.source,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory CuttingModel.fromEntity(CuttingEntity e) => CuttingModel(
    id: e.id,
    voucherNo: e.voucherNo,
    cuttingDate: e.cuttingDate,
    poNo: e.poNo,
    tagNo: e.tagNo,
    company: e.company,
    project: e.project,
    article: e.article,
    color: e.color,
    poQuantity: e.poQuantity,
    cuttingQuantity: e.cuttingQuantity,
    poTagNo: e.poTagNo,
    quantity: e.quantity,
    factoryName: e.factoryName,
    entryPerson: e.entryPerson,
    remarks: e.remarks,
    source: e.source,
    syncStatus: e.syncStatus,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  /// Reads a Firestore document defensively: legacy records may store numbers as
  /// strings, dates as `Timestamp` / `DateTime` / ISO strings and may only carry
  /// the legacy `poTagNo` + `quantity` fields.
  factory CuttingModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? {};
    final tagNo = _string(d['tagNo'] ?? d['poTagNo']);
    final cuttingQuantity = _int(d['cuttingQuantity'] ?? d['quantity']);
    return CuttingModel(
      id: s.id,
      voucherNo: _string(d['voucherNo']),
      cuttingDate: _date(d['cuttingDate']) ?? DateTime.now(),
      poNo: _string(d['poNo']),
      tagNo: tagNo,
      company: _string(d['company']),
      project: _string(d['project']),
      article: _string(d['article']),
      color: _string(d['color']),
      poQuantity: _int(d['poQuantity']),
      cuttingQuantity: cuttingQuantity,
      poTagNo: _string(d['poTagNo'] ?? tagNo),
      quantity: cuttingQuantity,
      factoryName: _string(d['factoryName']),
      entryPerson: _string(d['entryPerson']),
      remarks: _string(d['remarks']),
      source: _nullableString(d['source']),
      syncStatus: _nullableString(d['syncStatus']),
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'voucherNo': voucherNo,
    'cuttingDate': Timestamp.fromDate(cuttingDate),
    'poNo': poNo,
    'tagNo': tagNo,
    'poTagNo': poTagNo,
    'company': company,
    'project': project,
    'article': article,
    'color': color,
    'poQuantity': poQuantity,
    'cuttingQuantity': cuttingQuantity,
    // Keep the legacy alias while old reports/imports still read `quantity`.
    'quantity': cuttingQuantity,
    'factoryName': factoryName,
    'entryPerson': entryPerson,
    'remarks': remarks,
    'createdAt': createdAt == null
        ? Timestamp.now()
        : Timestamp.fromDate(createdAt!),
    'updatedAt': Timestamp.now(),
    'source': source ?? 'manual',
    'syncStatus': syncStatus ?? 'synced',
  };

  CuttingEntity toEntity() => CuttingEntity(
    id: id,
    voucherNo: voucherNo,
    cuttingDate: cuttingDate,
    poNo: poNo,
    tagNo: tagNo,
    company: company,
    project: project,
    article: article,
    color: color,
    poQuantity: poQuantity,
    cuttingQuantity: cuttingQuantity,
    poTagNo: poTagNo,
    quantity: quantity,
    factoryName: factoryName,
    entryPerson: entryPerson,
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

  static String? _nullableString(Object? value) {
    final text = _string(value);
    return text.isEmpty ? null : text;
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
