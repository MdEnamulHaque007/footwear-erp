import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/master_lc_entity.dart';
import '../../domain/repositories/i_master_lc_repository.dart';
import '../models/master_lc/master_lc_model.dart';

class MasterLCRepository implements IMasterLCRepository {
  MasterLCRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(AppConstants.collectionMasterLC);

  /// Keyset-pagination cursor: reset on page 0, advanced to the last doc read.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  Future<Either<String, List<MasterLCModel>>> getMasterLCList({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (page == 0) _lastDoc = null;
      var query = _collection.orderBy('sl');
      if (page > 0 && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snapshot = await query.limit(limit).get();
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

      final list = snapshot.docs
          .map((doc) => MasterLCModel.fromSnapshot(doc))
          .toList();

      return Right(list);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, MasterLCEntity?>> byTag(String tag) async {
    try {
      final s = await _collection.where('tagNo', isEqualTo: tag).limit(1).get();
      return Right(
        s.docs.isEmpty ? null : MasterLCModel.fromSnapshot(s.docs.first),
      );
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, MasterLCEntity?>> byId(String id) async {
    try {
      final snapshot = await _collection.doc(id).get();
      return Right(
        snapshot.exists ? MasterLCModel.fromSnapshot(snapshot) : null,
      );
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> createMasterLC(MasterLCEntity item) async {
    try {
      final ref = _collection.doc();
      final data = MasterLCModel.fromEntity(item).toFirestore();
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
  Future<Either<String, void>> update(MasterLCEntity item) async {
    try {
      await _collection
          .doc(item.id)
          .update(
            MasterLCModel(
              sl: item.sl,
              masterLcDate: item.masterLcDate,
              tagNo: item.tagNo,
              project: item.project,
              company: item.company,
              scNo: item.scNo,
              lcNo: item.lcNo,
              ttNo: item.ttNo,
              masterLcQuantity: item.masterLcQuantity,
              masterLcValue: item.masterLcValue,
            ).toFirestore(),
          );
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
