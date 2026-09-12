import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/cutting_entity.dart';

class CuttingModel extends CuttingEntity {
  const CuttingModel({
    super.id,
    required super.sl,
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
  });

  factory CuttingModel.fromEntity(CuttingEntity e) => CuttingModel(
    id: e.id,
    sl: e.sl,
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
  );

  factory CuttingModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? {};
    return CuttingModel(
      id: s.id,
      sl: d['sl'] as int? ?? 0,
      voucherNo: d['voucherNo'] as String? ?? '',
      cuttingDate: _date(d['cuttingDate']) ?? DateTime.now(),
      poNo: d['poNo'] as String? ?? '',
      tagNo: d['tagNo'] as String? ?? d['poTagNo'] as String? ?? '',
      company: d['company'] as String? ?? '',
      project: d['project'] as String? ?? '',
      article: d['article'] as String? ?? '',
      color: d['color'] as String? ?? '',
      poQuantity: (d['poQuantity'] as num? ?? 0).toInt(),
      cuttingQuantity:
          (d['cuttingQuantity'] as num? ?? d['quantity'] as num? ?? 0).toInt(),
      poTagNo: d['poTagNo'] as String? ?? d['tagNo'] as String? ?? '',
      quantity: (d['quantity'] as num? ?? d['cuttingQuantity'] as num? ?? 0)
          .toInt(),
      factoryName: d['factoryName'] as String? ?? '',
      entryPerson: d['entryPerson'] as String? ?? '',
      remarks: d['remarks'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sl': sl,
    'voucherNo': voucherNo,
    'cuttingDate': Timestamp.fromDate(cuttingDate),
    'poNo': poNo,
    'tagNo': tagNo,
    'company': company,
    'project': project,
    'article': article,
    'color': color,
    'poQuantity': poQuantity,
    'cuttingQuantity': cuttingQuantity,
    'poTagNo': poTagNo,
    'quantity': quantity,
    'factoryName': factoryName,
    'entryPerson': entryPerson,
    'remarks': remarks,
  };

  static DateTime? _date(Object? v) => v is Timestamp
      ? v.toDate()
      : v is DateTime
      ? v
      : null;
}
