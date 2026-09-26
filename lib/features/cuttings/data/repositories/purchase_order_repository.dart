import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.article,
    required this.color,
    required this.poQuantity,
  });

  final String article;
  final String color;
  final int poQuantity;
}

class PurchaseOrderSummary {
  const PurchaseOrderSummary({
    required this.poNo,
    required this.tagNo,
    required this.company,
    required this.project,
    required this.lineItems,
  });

  final String poNo;
  final String tagNo;
  final String company;
  final String project;
  final List<PurchaseOrderLine> lineItems;
}

class PurchaseOrderRepository {
  PurchaseOrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('purchase_orders');

  Future<PurchaseOrderSummary?> getByPoNo(String poNo) async {
    final snapshot =
        await _collection.where('poNo', isEqualTo: poNo.trim()).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    return PurchaseOrderSummary(
      poNo: data['poNo']?.toString() ?? poNo.trim(),
      tagNo: data['tagNo']?.toString() ?? '',
      company: data['company']?.toString() ?? '',
      project: data['project']?.toString() ?? '',
      lineItems: _lineItems(data['lineItems']),
    );
  }

  Future<List<String>> getPoNos() async {
    final snapshot = await _collection.orderBy('poNo').limit(1000).get();
    return snapshot.docs
        .map((doc) => doc.data()['poNo']?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  List<PurchaseOrderLine> _lineItems(Object? raw) {
    if (raw is! List) return const [];

    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return PurchaseOrderLine(
        article: map['article']?.toString().trim() ?? '',
        color: map['color']?.toString().trim() ?? '',
        poQuantity: _intValue(map['poQuantity'] ?? map['quantity']),
      );
    }).toList();
  }

  int _intValue(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }
}
