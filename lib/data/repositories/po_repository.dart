import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/repository_guard.dart';
import '../../domain/entities/po_entity.dart';
import '../../domain/repositories/i_po_repository.dart';
import '../models/purchase_order/po_model.dart';

class PORepository implements IPORepository {
  PORepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(AppConstants.collectionPO);

  /// Keyset-pagination cursor: reset on page 0, advanced to the last doc read.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  Future<Either<String, List<POModel>>> getPOList({
    int page = 0,
    int limit = 20,
  }) {
    return guard(() async {
      if (page == 0) _lastDoc = null;
      var query = _collection.orderBy('sl');
      if (page > 0 && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snapshot = await query.limit(limit).get();
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

      return snapshot.docs.map((doc) => POModel.fromSnapshot(doc)).toList();
    }, prefix: 'Database error');
  }

  @override
  Future<Either<String, List<POModel>>> byTag(String tag) {
    return guard(() async {
      final snapshot = await _collection
          .where('tagNo', isEqualTo: tag)
          .orderBy('sl')
          .get();
      return snapshot.docs.map((doc) => POModel.fromSnapshot(doc)).toList();
    }, prefix: 'Database error');
  }

  @override
  Future<Either<String, void>> createPO(POEntity item) {
    return guard(() async {
      final ref = _collection.doc();
      final data = POModel.fromEntity(item).toFirestore();
      data['id'] = ref.id;
      await ref.set(data);
    }, prefix: 'Failed to create');
  }

  @override
  Future<Either<String, void>> update(POEntity item) {
    return guard(() async {
      await _collection
          .doc(item.id)
          .update(POModel.fromEntity(item).toFirestore());
    }, prefix: 'Failed to update');
  }

  @override
  Future<Either<String, void>> delete(String id) {
    return guard(() async {
      await _collection.doc(id).delete();
    }, prefix: 'Failed to delete');
  }
}
