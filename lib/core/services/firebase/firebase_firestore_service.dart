/// ============================================================================
/// ফাইল: lib/core/services/firebase/firebase_firestore_service.dart
/// স্তর: Core | মডিউল: ERP Common
/// উদ্দেশ্য: Firebase Firestore Service সম্পর্কিত shared configuration, utility, service বা application-wide behavior প্রদান করে।
/// প্রধান অংশ: FirebaseFirestoreService
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../activity/activity_log_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseFirestoreService {
  FirebaseFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    await _firestore.collection(collection).add(data);
  }

  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getDocuments(
    String collection, {
    int limit = 20,
  }) async {
    const modules = {
      'master_lc': 'master_lc',
      'purchase_orders': 'purchase_order',
      'cuttings': 'cutting',
      'sewings': 'sewing',
      'productions': 'production',
      'issues': 'issue',
      'exports': 'export',
      'users': 'user_management',
      'roles': 'role_management',
      'settings': 'settings',
    };
    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> read() async {
      final snapshot = await _firestore
          .collection(collection)
          .limit(limit)
          .get();
      return snapshot.docs;
    }

    final module = modules[collection];
    if (module == null) return read();
    return ActivityLogService.instance.trackRead(
      module: module,
      operation: 'getDocuments',
      body: read,
    );
  }
}
