/// ============================================================================
/// ফাইল: lib/data/models/export/export_model.dart
/// স্তর: Data Model | মডিউল: Export
/// উদ্দেশ্য: Export entity এবং Firestore/JSON data-এর মধ্যে নিরাপদ রূপান্তর করে।
/// প্রধান অংশ: ExportModel
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/export_entity.dart';

class ExportModel extends ExportEntity {
  const ExportModel({
    super.id,
    required super.sl,
    required super.voucherNo,
    required super.exportDate,
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
    super.exportValue,
    super.issueQuantity,
    super.remarks,
    super.source,
    super.syncStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory ExportModel.fromEntity(ExportEntity e) => ExportModel(
    id: e.id,
    sl: e.sl,
    voucherNo: e.voucherNo,
    exportDate: e.exportDate,
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
    exportValue: e.exportValue,
    issueQuantity: e.issueQuantity,
    remarks: e.remarks,
    source: e.source,
    syncStatus: e.syncStatus,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  /// Reads a Firestore document defensively: legacy records may store numbers as
  /// strings, dates as `Timestamp` / `DateTime` / ISO strings and may only carry
  /// the legacy `poTagNo` + `quantity` fields.
  factory ExportModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? {};
    final primaryTagNo = _string(d['tagNo']);
    final tagNo = primaryTagNo.isNotEmpty ? primaryTagNo : _string(d['poTagNo']);
    final quantity = _int(d['quantity'] ?? d['exportQuantity']);
    return ExportModel(
      id: s.id,
      sl: _int(d['sl']),
      voucherNo: _string(d['voucherNo']),
      exportDate: _date(d['exportDate']) ?? DateTime.now(),
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
      exportValue: _double(d['exportValue']),
      issueQuantity: _int(d['issueQuantity']),
      remarks: _string(d['remarks']),
      source: d['source'] as String?,
      syncStatus: d['syncStatus'] as String?,
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'voucherNo': voucherNo,
    'exportDate': Timestamp.fromDate(exportDate),
    'exportQuantity': quantity,
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

  ExportEntity toEntity() => ExportEntity(
    id: id,
    sl: sl,
    voucherNo: voucherNo,
    exportDate: exportDate,
    poTagNo: tagNo,
    quantity: quantity,
    entryPerson: entryPerson,
    poNo: poNo,
    tagNo: tagNo,
    company: company,
    project: project,
    article: article,
    color: color,
    factoryName: factoryName,
    unitPrice: unitPrice,
    exportValue: exportValue,
    issueQuantity: issueQuantity,
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
