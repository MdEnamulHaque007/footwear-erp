import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/master_lc_entity.dart';

class MasterLCModel extends MasterLCEntity {
  const MasterLCModel({
    super.id,
    required super.sl,
    required super.masterLcDate,
    required super.tagNo,
    required super.project,
    required super.company,
    super.scNo,
    super.lcNo,
    super.ttNo,
    required super.masterLcQuantity,
    required super.masterLcValue,
  });
  factory MasterLCModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? {};
    return MasterLCModel(
      id: s.id,
      // Legacy / Sheets-imported rows may store numbers as strings, so parse
      // defensively instead of casting — a bare `as int` throws here.
      sl: _int(d['sl']),
      masterLcDate: _date(d['masterLcDate']) ?? DateTime.now(),
      tagNo: _string(d['tagNo']),
      project: _string(d['project']),
      company: _string(d['company']),
      scNo: _string(d['scNo']),
      lcNo: _string(d['lcNo']),
      ttNo: _string(d['ttNo']),
      masterLcQuantity: _int(d['masterLcQuantity']),
      masterLcValue: _double(d['masterLcValue']),
    );
  }
  factory MasterLCModel.fromEntity(MasterLCEntity e) => MasterLCModel(
    id: e.id,
    sl: e.sl,
    masterLcDate: e.masterLcDate,
    tagNo: e.tagNo,
    project: e.project,
    company: e.company,
    scNo: e.scNo,
    lcNo: e.lcNo,
    ttNo: e.ttNo,
    masterLcQuantity: e.masterLcQuantity,
    masterLcValue: e.masterLcValue,
  );
  Map<String, dynamic> toFirestore() => {
    'sl': sl,
    'masterLcDate': Timestamp.fromDate(masterLcDate),
    'tagNo': tagNo,
    'project': project,
    'company': company,
    'scNo': scNo,
    'lcNo': lcNo,
    'ttNo': ttNo,
    'masterLcQuantity': masterLcQuantity,
    'masterLcValue': masterLcValue,
    'createdAt': Timestamp.now(),
    'updatedAt': Timestamp.now(),
  };
  static DateTime? _date(Object? v) => v is Timestamp
      ? v.toDate()
      : v is DateTime
      ? v
      : v is String
      ? DateTime.tryParse(v)
      : null;

  /// Numbers may arrive as strings (Sheets imports), and text fields as numbers.
  /// Everything is coerced through `toString()` rather than cast, so a legacy
  /// document can never throw a cast error here.
  static String _string(Object? value) => value?.toString().trim() ?? '';

  static int _int(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  static double _double(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().trim() ?? '') ?? 0;
}
