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
  CollectionReference<Map<String, dynamic>> get _masterCollection =>
      _db.collection(AppConstants.collectionMasterLC);

  /// Transactionally-incremented sequence document backing [getMaxSl].
  DocumentReference<Map<String, dynamic>> get _counterDoc =>
      _db.collection(AppConstants.collectionCounters).doc('po');

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
  Future<Either<String, POModel?>> byId(String id) async {
    try {
      final snapshot = await _collection.doc(id).get();
      return Right(snapshot.exists ? POModel.fromSnapshot(snapshot) : null);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Next available serial number (max stored `sl` + 1, or 1 when empty).
  ///
  /// SRS Rule 1: the Sl. is auto-generated. Reads the counter document *and* the
  /// stored maximum, returning the higher of the two so legacy rows written
  /// before the counter existed cannot cause a collision.
  @override
  Future<int> getMaxSl() async {
    try {
      final counterSnapshot = await _counterDoc.get();
      final counter = counterSnapshot.data()?['value'];
      var next = counter is num ? counter.toInt() : 0;

      final snapshot = await _collection
          .orderBy('sl', descending: true)
          .limit(1)
          .get();
      final maxStored = snapshot.docs.isEmpty
          ? 0
          : _number(snapshot.docs.first.data()['sl']);

      if (maxStored > next) next = maxStored;
      return next + 1;
    } catch (_) {
      return 1;
    }
  }

  /// Whether [poNo] is free. PO No is unique **globally** across all tags.
  @override
  Future<bool> isPoNoUnique(String poNo, {String? excludeId}) async {
    final trimmed = poNo.trim();
    if (trimmed.isEmpty) return true;
    final snapshot = await _collection
        .where('poNo', isEqualTo: trimmed)
        .limit(10)
        .get();
    return snapshot.docs.every((doc) => doc.id == excludeId);
  }

  @override
  Future<Either<String, void>> createWithTransaction(POEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> updateWithTransaction(POEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  /// Validation + atomic write.
  ///
  /// Master LC and the sibling POs of the same tag are re-read **inside** the
  /// transaction, so two devices saving the same tag concurrently cannot both
  /// consume the same Master LC headroom: Firestore re-runs the transaction and
  /// the loser fails the limit check.
  Future<Either<String, void>> _writeWithTransaction(
    POEntity item, {
    required bool isUpdate,
  }) async {
    final ref = isUpdate && item.id != null
        ? _collection.doc(item.id)
        : _collection.doc();
    try {
      final data = POModel.fromEntity(item).toFirestore();
      data['id'] = ref.id;
      await _db.runTransaction<void>((transaction) async {
        // 0. PO No must be globally unique. The query runs outside the
        // transaction (6.x transactions read documents only) and the matched
        // documents are re-read transactionally so a concurrent insert is seen.
        final duplicateQuery = await _collection
            .where('poNo', isEqualTo: item.poNo.trim())
            .limit(10)
            .get();
        for (final doc in duplicateQuery.docs) {
          if (doc.id == ref.id) continue;
          final snapshot = await transaction.get(doc.reference);
          if (snapshot.exists) {
            throw _POValidationException(
              'PO No ${item.poNo.trim()} already exists',
            );
          }
        }

        // 1. Resolve the Master LC document for this tag. The query is run
        // outside the transaction (queries are unsupported by 6.x transactions)
        // but the document itself is re-read transactionally so its limits are
        // always current.
        final masterQuery = await _masterCollection
            .where('tagNo', isEqualTo: item.tagNo)
            .limit(1)
            .get();
        if (masterQuery.docs.isEmpty) {
          throw _POValidationException(
            'Master LC not found for tag ${item.tagNo}',
          );
        }
        final masterRef = masterQuery.docs.first.reference;
        final masterSnapshot = await transaction.get(masterRef);
        final master = masterSnapshot.data() ?? const <String, dynamic>{};
        final masterQuantity = _number(master['masterLcQuantity']);
        final masterValue = _double(master['masterLcValue']);

        // 2. Sibling POs of the same tag (self-excluded on update).
        final siblings = await _collection
            .where('tagNo', isEqualTo: item.tagNo)
            .limit(1000)
            .get();
        var usedQuantity = 0;
        var usedValue = 0.0;
        for (final doc in siblings.docs) {
          if (doc.id == ref.id) continue;
          final model = POModel.fromSnapshot(doc);
          usedQuantity += model.totalQuantity;
          usedValue += model.totalValue;
        }

        // 3. Validate against the persisted limits.
        final quantity = usedQuantity + item.totalQuantity;
        final value = usedValue + item.totalValue;
        if (quantity > masterQuantity) {
          throw _POValidationException(
            'PO quantity exceeds available Master LC quantity '
            '(available: ${masterQuantity - usedQuantity})',
          );
        }
        if (value > masterValue) {
          throw _POValidationException(
            'PO value exceeds available Master LC value '
            '(available: ${(masterValue - usedValue).toStringAsFixed(2)})',
          );
        }

        // 4. Atomic write with the auto-generated Sl.
        if (isUpdate) {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw const _POValidationException('PO no longer exists');
          }
          // The Sl. is immutable once assigned: keep the persisted value.
          data['sl'] = _number(snapshot.data()?['sl']);
          transaction.update(ref, data);
          return;
        }

        // Create path: allocate the next Sl. atomically.
        //
        // Firestore has no native auto-increment, so a counter document is
        // incremented inside the transaction. Firestore re-runs the transaction
        // on conflict, which makes the read-increment-write sequence atomic.
        final counterSnapshot = await transaction.get(_counterDoc);
        final stored = counterSnapshot.data()?['value'];
        var lastAssigned = stored is num ? stored.toInt() : 0;

        // Guard against records created before the counter existed.
        final latest = await _collection
            .orderBy('sl', descending: true)
            .limit(1)
            .get();
        final maxStored = latest.docs.isEmpty
            ? 0
            : _number(latest.docs.first.data()['sl']);
        if (maxStored > lastAssigned) lastAssigned = maxStored;

        final nextSl = lastAssigned + 1;
        data['sl'] = nextSl;
        transaction.set(ref, data);
        transaction.set(_counterDoc, {'value': nextSl});
      });
      return const Right(null);
    } on _POValidationException catch (e) {
      return Left(e.message);
    } on FirebaseException catch (e) {
      return Left(
        '${isUpdate ? 'Failed to update' : 'Failed to create'}: ${e.message}',
      );
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  static int _number(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  static double _double(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().trim() ?? '') ?? 0;

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

/// Internal marker so a failed transaction validation is surfaced to the user
/// verbatim instead of being wrapped in a generic Firestore error message.
class _POValidationException implements Exception {
  const _POValidationException(this.message);
  final String message;
}

