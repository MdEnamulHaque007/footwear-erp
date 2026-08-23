import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/production_entity.dart';

class ProductionModel extends ProductionEntity {
  const ProductionModel({
    super.id,
    required super.sl,
    required super.voucherNo,
    required super.productionDate,
    required super.poTagNo,
    required super.quantity,
    required super.entryPerson,
    super.remarks,
    super.createdAt,
    super.updatedAt,
  });

  factory ProductionModel.fromEntity(ProductionEntity e) => ProductionModel(
    id: e.id,
    sl: e.sl,
    voucherNo: e.voucherNo,
    productionDate: e.productionDate,
    poTagNo: e.poTagNo,
    quantity: e.quantity,
    entryPerson: e.entryPerson,
    remarks: e.remarks,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  factory ProductionModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> s,
  ) {
    final d = s.data() ?? {};
    return ProductionModel(
      id: s.id,
      sl: d['sl'] as int? ?? 0,
      voucherNo: d['voucherNo'] as String? ?? '',
      productionDate: _date(d['productionDate']) ?? DateTime.now(),
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
    'productionDate': Timestamp.fromDate(productionDate),
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
