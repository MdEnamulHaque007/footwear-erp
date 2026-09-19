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
    super.poNo,
    super.tagNo,
    super.company,
    super.project,
    super.article,
    super.color,
    super.factoryName,
    super.unitPrice,
    super.productionValue,
    super.sewingQuantity,
    super.remarks,
    super.source,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory ProductionModel.fromEntity(ProductionEntity e) => ProductionModel(
    id: e.id,
    sl: e.sl,
    voucherNo: e.voucherNo,
    productionDate: e.productionDate,
    poTagNo: e.tagNo,
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
    productionValue: e.productionValue,
    sewingQuantity: e.sewingQuantity,
    remarks: e.remarks,
    source: e.source,
    syncStatus: e.syncStatus,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  factory ProductionModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> s,
  ) {
    final d = s.data() ?? {};
    final primaryTagNo = _string(d['tagNo']);
    final tagNo = primaryTagNo.isNotEmpty ? primaryTagNo : _string(d['poTagNo']);
    final quantity = _int(d['quantity'] ?? d['productionQuantity']);
    return ProductionModel(
      id: s.id,
      sl: _int(d['sl']),
      voucherNo: _string(d['voucherNo']),
      productionDate: _date(d['productionDate']) ?? DateTime.now(),
      poTagNo: tagNo,
      quantity: quantity,
      entryPerson: _string(d['entryPerson']),
      poNo: _string(d['poNo']),
      tagNo: tagNo,
      company: _string(d['company']),
      project: _string(d['project']),
      article: _string(d['article']),
      color: _string(d['color']),
      factoryName: _string(d['factoryName']),
      unitPrice: _double(d['unitPrice']),
      productionValue: _double(d['productionValue']),
      sewingQuantity: _int(d['sewingQuantity']),
      remarks: _string(d['remarks']),
      source: d['source'] as String?,
      syncStatus: d['syncStatus'] as String?,
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'voucherNo': voucherNo,
    'productionDate': Timestamp.fromDate(productionDate),
    'quantity': quantity,
    'productionQuantity': quantity,
    'entryPerson': entryPerson,
    'poNo': poNo,
    'tagNo': tagNo,
    'poTagNo': tagNo,
    'article': article,
    'color': color,
    'factoryName': factoryName,
    'remarks': remarks,
    'createdAt': createdAt == null
        ? Timestamp.now()
        : Timestamp.fromDate(createdAt!),
    'updatedAt': Timestamp.now(),
    'source': source ?? 'manual',
    'syncStatus': syncStatus ?? 'synced',
  };

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

