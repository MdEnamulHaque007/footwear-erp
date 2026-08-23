import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/po_entity.dart';
class POModel extends POEntity {
  const POModel({super.id, required super.sl, required super.poDate, required super.tagNo, required super.company, required super.project, required super.brand, required super.poNo, required super.article, required super.color, required super.poQuantity, required super.unitPrice, required super.entryPerson});
  factory POModel.fromEntity(POEntity e) => POModel(id: e.id, sl: e.sl, poDate: e.poDate, tagNo: e.tagNo, company: e.company, project: e.project, brand: e.brand, poNo: e.poNo, article: e.article, color: e.color, poQuantity: e.poQuantity, unitPrice: e.unitPrice, entryPerson: e.entryPerson);
  factory POModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) { final d = s.data() ?? {}; return POModel(id: s.id, sl: d['sl'] as int? ?? 0, poDate: _date(d['poDate']) ?? DateTime.now(), tagNo: d['tagNo'] as String? ?? '', company: d['company'] as String? ?? '', project: d['project'] as String? ?? '', brand: d['brand'] as String? ?? '', poNo: d['poNo'] as String? ?? '', article: d['article'] as String? ?? '', color: d['color'] as String? ?? '', poQuantity: d['poQuantity'] as int? ?? 0, unitPrice: (d['unitPrice'] as num? ?? 0).toDouble(), entryPerson: d['entryPerson'] as String? ?? ''); }
  Map<String, dynamic> toFirestore() => {'sl': sl, 'poDate': Timestamp.fromDate(poDate), 'tagNo': tagNo, 'company': company, 'project': project, 'brand': brand, 'poNo': poNo, 'article': article, 'color': color, 'poQuantity': poQuantity, 'unitPrice': unitPrice, 'poValue': poValue, 'entryPerson': entryPerson};
  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : v is DateTime ? v : null;
}
