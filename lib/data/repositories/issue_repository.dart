import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/repositories/i_issue_repository.dart';
import '../models/issue/issue_model.dart';

class IssueRepository implements IIssueRepository {
  IssueRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(AppConstants.collectionIssue);

  /// Keyset-pagination cursor: reset on page 0, advanced to the last doc read.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  Future<Either<String, List<IssueModel>>> getIssueList({
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

      final list = snapshot.docs.map(IssueModel.fromSnapshot).toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<IssueModel>>> byPoTag(String poTagNo) async {
    try {
      final s = await _collection
          .where('poTagNo', isEqualTo: poTagNo)
          .orderBy('sl')
          .get();
      return Right(s.docs.map(IssueModel.fromSnapshot).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> createIssue(IssueEntity item) async {
    try {
      final ref = _collection.doc();
      final data = IssueModel.fromEntity(item).toFirestore();
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
  Future<Either<String, void>> update(IssueEntity item) async {
    try {
      final data = IssueModel.fromEntity(item).toFirestore();
      data['updatedAt'] = Timestamp.now();
      await _collection.doc(item.id).update(data);
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
  Future<int> getCumulativeIssueQuantity({
    required String poTagNo,
    required DateTime upToDate,
    String? excludingId,
  }) async {
    final snapshot = await _collection
        .where('poTagNo', isEqualTo: poTagNo)
        .where('issueDate', isLessThanOrEqualTo: Timestamp.fromDate(upToDate))
        .get();
    return snapshot.docs
        .where((doc) => doc.id != excludingId)
        .fold<int>(
          0,
          (total, doc) =>
              total + ((doc.data()['quantity'] as num?) ?? 0).toInt(),
        );
  }
}
