import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/po_entity.dart';

class POLineItemModel extends POLineItemEntity {
  const POLineItemModel({
    required super.article,
    required super.color,
    required super.poQuantity,
    required super.unitPrice,
  });

  factory POLineItemModel.fromMap(Map<String, dynamic> data) => POLineItemModel(
    article: _string(data['article'] ?? data['articleNo']),
    color: _string(data['color'] ?? data['colour']),
    poQuantity: _number(data['poQuantity'] ?? data['quantity']),
    unitPrice: (data['unitPrice'] as num? ?? 0).toDouble(),
  );

  static String _string(Object? value) => value?.toString().trim() ?? '';
  static int _number(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  Map<String, dynamic> toMap() => {
    'article': article,
    'color': color,
    'poQuantity': poQuantity,
    'unitPrice': unitPrice,
    'poValue': poValue,
  };
}

class POModel extends POEntity {
  const POModel({
    super.id,
    required super.sl,
    required super.poDate,
    required super.tagNo,
    required super.company,
    required super.project,
    required super.brand,
    required super.poNo,
    required super.entryPerson,
    required super.lineItems,
    super.article,
    super.color,
    super.poQuantity,
    super.unitPrice,
    super.createdAt,
    super.updatedAt,
  });

  factory POModel.fromEntity(POEntity e) => POModel(
    id: e.id,
    sl: e.sl,
    poDate: e.poDate,
    tagNo: e.tagNo,
    company: e.company,
    project: e.project,
    brand: e.brand,
    poNo: e.poNo,
    entryPerson: e.entryPerson,
    lineItems: e.effectiveLineItems
        .map(
          (item) => POLineItemModel(
            article: item.article,
            color: item.color,
            poQuantity: item.poQuantity,
            unitPrice: item.unitPrice,
          ),
        )
        .toList(),
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  factory POModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final data = s.data() ?? {};
    final rawItems = data['lineItems'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) =>
                    POLineItemModel.fromMap(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.article.isNotEmpty || item.color.isNotEmpty)
              .toList()
        : <POLineItemModel>[];
    return POModel(
      id: s.id,
      sl: (data['sl'] as num? ?? 0).toInt(),
      poDate: _date(data['poDate']) ?? DateTime.now(),
      tagNo: data['tagNo'] as String? ?? '',
      company: data['company'] as String? ?? '',
      project: data['project'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      poNo: data['poNo'] as String? ?? '',
      entryPerson: data['entryPerson'] as String? ?? '',
      lineItems: items,
      article: data['article'] as String? ?? '',
      color: data['color'] as String? ?? '',
      poQuantity: POLineItemModel._number(
        data['poQuantity'] ?? data['quantity'],
      ),
      unitPrice: (data['unitPrice'] as num? ?? 0).toDouble(),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sl': sl,
    'poDate': Timestamp.fromDate(poDate),
    'tagNo': tagNo,
    'company': company,
    'project': project,
    'brand': brand,
    'poNo': poNo,
    'entryPerson': entryPerson,
    'lineItems': effectiveLineItems
        .map(
          (item) => POLineItemModel(
            article: item.article,
            color: item.color,
            poQuantity: item.poQuantity,
            unitPrice: item.unitPrice,
          ).toMap(),
        )
        .toList(),
    'totalQuantity': totalQuantity,
    'totalValue': totalValue,
    'createdAt': createdAt == null
        ? Timestamp.now()
        : Timestamp.fromDate(createdAt!),
    'updatedAt': Timestamp.now(),
  };

  static DateTime? _date(Object? value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : null;
}
