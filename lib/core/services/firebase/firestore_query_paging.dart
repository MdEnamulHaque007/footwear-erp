import 'package:cloud_firestore/cloud_firestore.dart';

class CompleteQueryResult {
  const CompleteQueryResult(this.docs);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

/// Pages through every matching document; totals never use a capped sample.
/// Existing order/filter constraints are preserved, and the last document is
/// a deterministic cursor even when several records share an ordered value.
extension CompleteFirestoreQuery on Query<Map<String, dynamic>> {
  Future<CompleteQueryResult> getAll() async {
    final documents = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    Query<Map<String, dynamic>> query = this;
    const pageSize = 500;
    while (true) {
      final page = await query.limit(pageSize).get();
      documents.addAll(page.docs);
      if (page.docs.length < pageSize) break;
      query = startAfterDocument(page.docs.last);
    }
    return CompleteQueryResult(documents);
  }
}
