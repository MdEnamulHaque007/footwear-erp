import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/po_entity.dart';
import '../../domain/repositories/i_po_repository.dart';
import '../models/purchase_order/po_model.dart';

class PORepository implements IPORepository {
  PORepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection => _db.collection(AppConstants.collectionPO);

  /// Keyset-pagination cursor: reset on page 0, advanced to the last doc read.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  Future<Either<String, List<POModel>>> getPOList({int page = 0, int limit = 20}) async {
    try {
      if (page == 0) _lastDoc = null;
      var query = _collection.orderBy('sl');
      if (page > 0 && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snapshot = await query.limit(limit).get();
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

      final list = snapshot.docs
          .map((doc) => POModel.fromSnapshot(doc))
          .toList();

      return Right(list);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<POModel>>> byTag(String tag) async {
    try {
      final snapshot = await _collection.where('tagNo', isEqualTo: tag).get(); 
      final list = snapshot.docs.map((doc) => POModel.fromSnapshot(doc)).toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> createPO(POEntity item) async {
    try {
      final ref = _collection.doc();
      final data = POModel.fromEntity(item).toFirestore();
      data['id'] = ref.id;
      await ref.set(data);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Failed to create: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> update(POEntity item) async {
    try {
      await _collection.doc(item.id).update(POModel(
        sl: item.sl, 
        poDate: item.poDate, 
        tagNo: item.tagNo, 
        company: item.company, 
        project: item.project, 
        brand: item.brand, 
        poNo: item.poNo, 
        article: item.article, 
        color: item.color, 
        poQuantity: item.poQuantity, 
        unitPrice: item.unitPrice, 
        entryPerson: item.entryPerson
      ).toFirestore());
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Failed to update: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> delete(String id) async {
    try {
      await _collection.doc(id).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Failed to delete: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }
}
