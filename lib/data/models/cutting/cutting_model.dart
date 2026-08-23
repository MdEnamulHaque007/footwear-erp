import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/cutting_entity.dart';

class CuttingModel extends CuttingEntity {
  const CuttingModel({
    super.id,
    required super.sl,
    required super.voucherNo,
    required super.cuttingDate,
    required super.poTagNo,
    required super.quantity,
    required super.entryPerson,
    super.remarks,
  });

  factory CuttingModel.fromEntity(CuttingEntity e) => CuttingModel(
    id: e.id,
    sl: e.sl,
    voucherNo: e.voucherNo,
    cuttingDate: e.cuttingDate,
    poTagNo: e.poTagNo,
    quantity: e.quantity,
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
      poTagNo: d['poTagNo'] as String? ?? '',
      quantity: d['quantity'] as int? ?? 0,
      entryPerson: d['entryPerson'] as String? ?? '',
      remarks: d['remarks'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sl': sl,
    'voucherNo': voucherNo,
    'cuttingDate': Timestamp.fromDate(cuttingDate),
    'poTagNo': poTagNo,
    'quantity': quantity,
    'entryPerson': entryPerson,
    'remarks': remarks,
  };

  static DateTime? _date(Object? v) => v is Timestamp
      ? v.toDate()
      : v is DateTime
      ? v
      : null;
}
