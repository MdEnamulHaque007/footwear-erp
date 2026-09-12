import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/cutting_entity.dart';
import '../../domain/repositories/i_cutting_repository.dart';
import '../models/cutting/cutting_model.dart';
import '../models/purchase_order/po_model.dart';

class CuttingRepository implements ICuttingRepository {
  CuttingRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(AppConstants.collectionCutting);
  CollectionReference<Map<String, dynamic>> get _poCollection =>
      _db.collection(AppConstants.collectionPO);

  /// Keyset-pagination cursor: reset on page 0, advanced to the last doc read.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  Future<Either<String, List<CuttingModel>>> getCuttingList({
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

      final list = snapshot.docs.map(CuttingModel.fromSnapshot).toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<CuttingModel>>> byPoTag(String poTagNo) async {
    try {
      final s = await _collection
          .where('poTagNo', isEqualTo: poTagNo)
          .orderBy('sl')
          .get();
      return Right(s.docs.map(CuttingModel.fromSnapshot).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, CuttingModel?>> byId(String id) async {
    try {
      final snapshot = await _collection.doc(id).get();
      return Right(
        snapshot.exists ? CuttingModel.fromSnapshot(snapshot) : null,
      );
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<CuttingModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  }) async {
    try {
      // Keep this query index-independent. Article and color are filtered and
      // sorted locally so the detail view also works before composite indexes
      // finish building in Firestore.
      final snapshot = await _collection
          .where('poNo', isEqualTo: poNo)
          .limit(1000)
          .get();
      final normalizedArticle = article.trim().toLowerCase();
      final normalizedColor = color.trim().toLowerCase();
      final entries =
          snapshot.docs
              .map(CuttingModel.fromSnapshot)
              .where(
                (item) =>
                    item.article.trim().toLowerCase() == normalizedArticle &&
                    item.color.trim().toLowerCase() == normalizedColor,
              )
              .toList()
            ..sort((a, b) => b.cuttingDate.compareTo(a.cuttingDate));
      return Right(entries);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<String>>> getPONoList() async {
    try {
      final snapshot = await _poCollection.orderBy('poNo').limit(100).get();
      return Right(
        snapshot.docs
            .map((doc) => doc.data()['poNo'] as String? ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(),
      );
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<POModel>>> getPOListForDropdown() async {
    try {
      final snapshot = await _poCollection.orderBy('poNo').limit(100).get();
      return Right(snapshot.docs.map(POModel.fromSnapshot).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, POModel?>> getPOByNo(String poNo) async {
    try {
      final snapshot = await _poCollection
          .where('poNo', isEqualTo: poNo)
          .limit(1)
          .get();
      return Right(
        snapshot.docs.isEmpty
            ? null
            : POModel.fromSnapshot(snapshot.docs.first),
      );
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> createCutting(CuttingEntity item) async {
    try {
      final ref = _collection.doc();
      final data = CuttingModel.fromEntity(item).toFirestore();
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
  Future<Either<String, void>> update(CuttingEntity item) async {
    try {
      await _collection
          .doc(item.id)
          .update(CuttingModel.fromEntity(item).toFirestore());
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

  @override
  Future<int> getCumulativeCuttingQuantity({
    required String poTagNo,
    required DateTime upToDate,
  }) async {
    final snapshot = await _collection
        .where('poTagNo', isEqualTo: poTagNo)
        .where('cuttingDate', isLessThanOrEqualTo: Timestamp.fromDate(upToDate))
        .get();
    return snapshot.docs.fold<int>(
      0,
      (total, doc) => total + ((doc.data()['quantity'] as num?) ?? 0).toInt(),
    );
  }

  @override
  Future<int> getCumulativeCuttingQuantityByLine({
    required String poNo,
    required String article,
    required String color,
    String? excludingId,
  }) async {
    final snapshot = await _collection
        .where('poNo', isEqualTo: poNo)
        .where('article', isEqualTo: article)
        .where('color', isEqualTo: color)
        .limit(1000)
        .get();
    return snapshot.docs
        .where((doc) => doc.id != excludingId)
        .fold<int>(
          0,
          (total, doc) =>
              total +
              ((doc.data()['cuttingQuantity'] as num?) ??
                      (doc.data()['quantity'] as num?) ??
                      0)
                  .toInt(),
        );
  }
}
