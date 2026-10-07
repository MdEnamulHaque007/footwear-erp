import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/activity/activity_log_entry.dart';

class ActivityLogPage {
  const ActivityLogPage({
    required this.entries,
    required this.hasMore,
    this.cursor,
  });
  final List<ActivityLogEntry> entries;
  final bool hasMore;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
}

/// Reads the log itself without creating another log (avoids recursion).
class ActivityLogRepository {
  ActivityLogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore;
  final FirebaseFirestore? _firestore;
  static const pageSize = 50;

  Future<ActivityLogPage> load({
    String? module,
    String? action,
    String? actorUid,
    DateTime? from,
    DateTime? toExclusive,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    Query<Map<String, dynamic>> query =
        (_firestore ?? FirebaseFirestore.instance).collection('audit_logs');
    if (module != null) query = query.where('module', isEqualTo: module);
    if (action != null) query = query.where('action', isEqualTo: action);
    if (actorUid != null && actorUid.isNotEmpty) {
      query = query.where('actorUid', isEqualTo: actorUid);
    }
    if (from != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    }
    if (toExclusive != null) {
      query = query.where(
        'createdAt',
        isLessThan: Timestamp.fromDate(toExclusive),
      );
    }
    query = query
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (after != null) query = query.startAfterDocument(after);
    final snapshot = await query.limit(pageSize + 1).get();
    final docs = snapshot.docs.take(pageSize).toList();
    return ActivityLogPage(
      entries: docs.map((doc) {
        final data = doc.data();
        final time = data['createdAt'];
        if (time is Timestamp) data['createdAt'] = time.toDate();
        return ActivityLogEntry(id: doc.id, data: data);
      }).toList(),
      hasMore: snapshot.docs.length > pageSize,
      cursor: docs.isEmpty ? after : docs.last,
    );
  }
}
