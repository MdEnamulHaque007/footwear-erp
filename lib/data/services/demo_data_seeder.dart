/// ============================================================================
/// ফাইল: lib/data/services/demo_data_seeder.dart
/// স্তর: Data Service | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common সংক্রান্ত reusable data processing ও সহায়ক operation প্রদান করে।
/// প্রধান অংশ: DemoDataSeeder
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';

/// Generates clearly-marked demo records for local/staging testing.
///
/// Each selected module receives [count] records. A run of 3,000 therefore
/// creates 21,000 documents across the seven ERP collections.
class DemoDataSeeder {
  DemoDataSeeder({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const marker = 'footwear-erp-demo-v1';
  static const batchSize = 450;
  static const collections = <String>[
    'master_lc',
    'purchase_orders',
    'cuttings',
    'sewings',
    'productions',
    'issues',
    'exports',
  ];

  final FirebaseFirestore _firestore;

  Future<void> seed({
    required int count,
    void Function(String collection, int done, int total)? onProgress,
  }) async {
    if (count < 3000 || count > 5000) {
      throw ArgumentError.value(count, 'count', 'must be between 3000 and 5000');
    }

    for (final collection in collections) {
      for (var start = 0; start < count; start += batchSize) {
        final end = (start + batchSize).clamp(0, count);
        final batch = _firestore.batch();
        for (var i = start; i < end; i++) {
          final id = _id(collection, i + 1);
          batch.set(
            _firestore.collection(collection).doc(id),
            _record(collection, i + 1),
            SetOptions(merge: true),
          );
        }
        await batch.commit();
        onProgress?.call(collection, end, count);
      }
    }
  }

  Future<int> clear({
    void Function(String collection, int deleted)? onProgress,
  }) async {
    var totalDeleted = 0;
    for (final collection in collections) {
      var deleted = 0;
      while (true) {
        final snapshot = await _firestore
            .collection(collection)
            .where('demoSeed', isEqualTo: marker)
            .limit(batchSize)
            .get();
        if (snapshot.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        deleted += snapshot.docs.length;
        totalDeleted += snapshot.docs.length;
        onProgress?.call(collection, deleted);
      }
    }
    return totalDeleted;
  }

  String _id(String collection, int number) {
    final prefix = switch (collection) {
      'master_lc' => 'mlc',
      'purchase_orders' => 'po',
      'cuttings' => 'cut',
      'sewings' => 'sew',
      'productions' => 'prod',
      'issues' => 'iss',
      'exports' => 'exp',
      _ => 'demo',
    };
    return 'demo-$prefix-${number.toString().padLeft(5, '0')}';
  }

  Map<String, dynamic> _record(String collection, int n) {
    final poNo = 'DEMO-PO-${((n - 1) % 500 + 1).toString().padLeft(4, '0')}';
    final tagNo = 'DEMO-TAG-${n.toString().padLeft(5, '0')}';
    final company = 'Demo Footwear ${n % 8 + 1}';
    final project = 'Demo Project ${n % 12 + 1}';
    final article = 'ART-${100 + n % 60}';
    final color = ['Black', 'White', 'Brown', 'Navy', 'Red'][n % 5];
    final factory = 'Demo Factory ${n % 6 + 1}';
    final quantity = 100 + (n % 901);
    final date = Timestamp.fromDate(DateTime(2025, 1, 1).add(Duration(days: n % 365)));

    final base = <String, dynamic>{
      'demoSeed': marker,
      'source': 'demo_seed',
      'sl': n,
      'companyName': company,
      'projectName': project,
      'articleNo': article,
      'article': article,
      'color': color,
      'factoryName': factory,
      'entryPerson': 'Demo Admin',
      'remarks': 'Generated demo data — safe to delete from Admin > Demo Data.',
      'createdAt': date,
      'updatedAt': date,
    };

    switch (collection) {
      case 'master_lc':
        return {
          ...base,
          'tagNo': 'DEMO-LC-${n.toString().padLeft(5, '0')}',
          'lcNo': 'DEMO-LC-${n.toString().padLeft(5, '0')}',
          'lcDate': date,
          'buyerName': ['Demo Buyer A', 'Demo Buyer B', 'Demo Buyer C'][n % 3],
          'currency': 'USD',
          'quantity': quantity,
          'masterLcQuantity': quantity,
          'unitPrice': 12.5 + (n % 20) / 10,
          'masterLcValue': quantity * (12.5 + (n % 20) / 10),
          'status': n % 7 == 0 ? 'Closed' : 'Active',
        };
      case 'purchase_orders':
        return {
          ...base,
          'poNo': poNo,
          'tagNo': tagNo,
          'masterLcTagNo': 'DEMO-LC-${((n - 1) % 500 + 1).toString().padLeft(5, '0')}',
          'poDate': date,
          'quantity': quantity,
          'totalQuantity': quantity,
          'unitPrice': 12.5 + (n % 20) / 10,
          'totalValue': quantity * (12.5 + (n % 20) / 10),
          'status': n % 6 == 0 ? 'Completed' : 'Open',
        };
      case 'cuttings':
        return {
          ...base,
          'poNo': poNo,
          'tagNo': tagNo,
          'cuttingDate': date,
          'quantity': quantity,
          'cuttingQuantity': quantity,
          'status': 'Completed',
        };
      case 'sewings':
        return {
          ...base,
          'poNo': poNo,
          'tagNo': tagNo,
          'sewingDate': date,
          'quantity': quantity,
          'sewingQuantity': quantity,
          'status': 'Completed',
        };
      case 'productions':
        return {
          ...base,
          'poNo': poNo,
          'tagNo': tagNo,
          'poTagNo': tagNo,
          'voucherNo': 'DEMO-PROD-${n.toString().padLeft(5, '0')}',
          'productionDate': date,
          'quantity': quantity,
          'productionQuantity': quantity,
          'sewingQuantity': quantity,
          'unitPrice': 12.5 + (n % 20) / 10,
          'productionValue': quantity * (12.5 + (n % 20) / 10),
        };
      case 'issues':
        return {
          ...base,
          'poNo': poNo,
          'tagNo': tagNo,
          'poTagNo': tagNo,
          'voucherNo': 'DEMO-ISSUE-${n.toString().padLeft(5, '0')}',
          'issueDate': date,
          'quantity': quantity,
          'issueQuantity': quantity,
          'status': 'Issued',
        };
      case 'exports':
        return {
          ...base,
          'poNo': poNo,
          'tagNo': tagNo,
          'poTagNo': tagNo,
          'voucherNo': 'DEMO-EXP-${n.toString().padLeft(5, '0')}',
          'exportDate': date,
          'quantity': quantity,
          'exportQuantity': quantity,
          'buyerName': ['Demo Buyer A', 'Demo Buyer B', 'Demo Buyer C'][n % 3],
          'status': 'Exported',
        };
      default:
        return base;
    }
  }
}
