import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/master_lc_entity.dart';
class MasterLCModel extends MasterLCEntity {
  const MasterLCModel({super.id, required super.sl, required super.masterLcDate, required super.tagNo, required super.project, required super.company, super.scNo, super.lcNo, super.ttNo, required super.masterLcQuantity, required super.masterLcValue});
  factory MasterLCModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) { final d = s.data() ?? {}; return MasterLCModel(id: s.id, sl: d['sl'] as int? ?? 0, masterLcDate: _date(d['masterLcDate']) ?? DateTime.now(), tagNo: d['tagNo'] as String? ?? '', project: d['project'] as String? ?? '', company: d['company'] as String? ?? '', scNo: d['scNo'] as String? ?? '', lcNo: d['lcNo'] as String? ?? '', ttNo: d['ttNo'] as String? ?? '', masterLcQuantity: d['masterLcQuantity'] as int? ?? 0, masterLcValue: (d['masterLcValue'] as num? ?? 0).toDouble()); }
  factory MasterLCModel.fromEntity(MasterLCEntity e) => MasterLCModel(id: e.id, sl: e.sl, masterLcDate: e.masterLcDate, tagNo: e.tagNo, project: e.project, company: e.company, scNo: e.scNo, lcNo: e.lcNo, ttNo: e.ttNo, masterLcQuantity: e.masterLcQuantity, masterLcValue: e.masterLcValue);
  Map<String, dynamic> toFirestore() => {'sl': sl, 'masterLcDate': Timestamp.fromDate(masterLcDate), 'tagNo': tagNo, 'project': project, 'company': company, 'scNo': scNo, 'lcNo': lcNo, 'ttNo': ttNo, 'masterLcQuantity': masterLcQuantity, 'masterLcValue': masterLcValue};
  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : v is DateTime ? v : null;
}
