import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/issue_entity.dart';

class IssueModel extends IssueEntity {
  const IssueModel({
    super.id,
    required super.sl,
    required super.voucherNo,
    required super.issueDate,
    required super.poTagNo,
    required super.quantity,
    required super.entryPerson,
    super.remarks,
    super.createdAt,
    super.updatedAt,
  });

  factory IssueModel.fromEntity(IssueEntity e) => IssueModel(
    id: e.id,
    sl: e.sl,
    voucherNo: e.voucherNo,
    issueDate: e.issueDate,
    poTagNo: e.poTagNo,
    quantity: e.quantity,
    entryPerson: e.entryPerson,
    remarks: e.remarks,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  factory IssueModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data() ?? {};
    return IssueModel(
      id: s.id,
      sl: d['sl'] as int? ?? 0,
      voucherNo: d['voucherNo'] as String? ?? '',
      issueDate: _date(d['issueDate']) ?? DateTime.now(),
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
    'issueDate': Timestamp.fromDate(issueDate),
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
