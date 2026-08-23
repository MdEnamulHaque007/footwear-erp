import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/sewing_entity.dart';

class SewingModel extends SewingEntity {
  const SewingModel({
    super.id,
    required super.sl,
    required super.voucherNo,
    required super.sewingDate,
    required super.poTagNo,
    required super.quantity,
    required super.entryPerson,
    super.remarks,
    super.createdAt,
    super.updatedAt,
  });

  factory SewingModel.fromEntity(SewingEntity e) => SewingModel(
    id: e.id,
    sl: e.sl,
    voucherNo: e.voucherNo,
    sewingDate: e.sewingDate,
    poTagNo: e.poTagNo,
    quantity: e.quantity,
    entryPerson: e.entryPerson,
    remarks: e.remarks,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  factory SewingModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? {};
    return SewingModel(
      id: s.id,
      sl: d['sl'] as int? ?? 0,
      voucherNo: d['voucherNo'] as String? ?? '',
      sewingDate: _date(d['sewingDate']) ?? DateTime.now(),
      poTagNo: d['poTagNo'] as String? ?? '',
      quantity: d['quantity'] as int? ?? 0,
      entryPerson: d['entryPerson'] as String? ?? '',
      remarks: d['remarks'] as String? ?? '',
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sl': sl,
    'voucherNo': voucherNo,
    'sewingDate': Timestamp.fromDate(sewingDate),
    'poTagNo': poTagNo,
    'quantity': quantity,
    'entryPerson': entryPerson,
    'remarks': remarks,
    'createdAt': createdAt == null
        ? Timestamp.now()
        : Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };

  static DateTime? _date(Object? v) => v is Timestamp
      ? v.toDate()
      : v is DateTime
      ? v
      : null;
}
