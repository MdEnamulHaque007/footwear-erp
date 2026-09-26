/// ============================================================================
/// ফাইল: lib/data/models/sewing/sewing_model.dart
/// স্তর: Data Model | মডিউল: Sewing
/// উদ্দেশ্য: Sewing entity এবং Firestore/JSON data-এর মধ্যে নিরাপদ রূপান্তর করে।
/// প্রধান অংশ: SewingModel
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/sewing_entity.dart';

class SewingModel extends SewingEntity {
  SewingModel({
    super.id,
    required super.sl,
    required super.voucherNo,
    required super.sewingDate,
    super.poNo,
    super.tagNo,
    super.company,
    super.project,
    super.article,
    super.color,
    super.cuttingQuantity,
    super.sewingQuantity,
    super.poTagNo,
    super.quantity,
    super.factoryName,
    required super.entryPerson,
    super.remarks,
    super.createdAt,
    super.updatedAt,
    super.source,
    super.syncStatus,
  });

  factory SewingModel.fromEntity(SewingEntity e) => SewingModel(
    id: e.id,
    sl: e.sl,
    voucherNo: e.voucherNo,
    sewingDate: e.sewingDate,
    poNo: e.poNo,
    tagNo: e.tagNo,
    company: e.company,
    project: e.project,
    article: e.article,
    color: e.color,
    cuttingQuantity: e.cuttingQuantity,
    sewingQuantity: e.effectiveQuantity,
    poTagNo: e.tagNo,
    quantity: e.quantity,
    factoryName: e.factoryName,
    entryPerson: e.entryPerson,
    remarks: e.remarks,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
    source: e.source,
    syncStatus: e.syncStatus,
  );

  /// Reads a Firestore document defensively: legacy records may store numbers
  /// as strings, dates as `Timestamp` / `DateTime` / ISO strings and may only
  /// carry the legacy `poTagNo` + `quantity` fields.
  factory SewingModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final data = s.data() ?? {};
    final primaryTagNo = _string(data['tagNo']);
    final tagNo = primaryTagNo.isNotEmpty ? primaryTagNo : _string(data['poTagNo']);
    final sewingQuantity = _int(data['sewingQuantity'] ?? data['quantity']);
    return SewingModel(
      id: s.id,
      sl: _int(data['sl']),
      voucherNo: _string(data['voucherNo']),
      sewingDate: _date(data['sewingDate']) ?? DateTime.now(),
      poNo: _string(data['poNo']),
      tagNo: tagNo,
      company: _string(data['company']),
      project: _string(data['project']),
      article: _string(data['article']),
      color: _string(data['color']),
      cuttingQuantity: _int(data['cuttingQuantity']),
      sewingQuantity: sewingQuantity,
      poTagNo: tagNo,
      quantity: sewingQuantity,
      factoryName: _string(data['factoryName']),
      entryPerson: _string(data['entryPerson']),
      remarks: _string(data['remarks']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      source: data['source'] as String?,
      syncStatus: data['syncStatus'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'voucherNo': voucherNo,
    'sewingDate': Timestamp.fromDate(sewingDate),
    'poNo': poNo,
    'tagNo': tagNo,
    'poTagNo': tagNo,
    'article': article,
    'color': color,
    'sewingQuantity': effectiveQuantity,
    'factoryName': factoryName,
    'entryPerson': entryPerson,
    'remarks': remarks,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.now(),
    'source': source ?? 'manual',
    'syncStatus': syncStatus ?? 'synced',
  };

  SewingEntity toEntity() => SewingEntity(
    id: id,
    sl: sl,
    voucherNo: voucherNo,
    sewingDate: sewingDate,
    poNo: poNo,
    tagNo: tagNo,
    company: company,
    project: project,
    article: article,
    color: color,
    cuttingQuantity: cuttingQuantity,
    sewingQuantity: sewingQuantity,
    poTagNo: tagNo,
    quantity: quantity,
    factoryName: factoryName,
    entryPerson: entryPerson,
    remarks: remarks,
    createdAt: createdAt,
    updatedAt: updatedAt,
    source: source,
    syncStatus: syncStatus,
  );

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static int _int(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
