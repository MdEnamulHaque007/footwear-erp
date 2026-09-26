/// ============================================================================
/// ফাইল: lib/data/repositories/master_lc_repository.dart
/// স্তর: Data Repository | মডিউল: Master LC
/// উদ্দেশ্য: Master LC data query, transaction, pagination ও persistence বাস্তবায়ন করে।
/// প্রধান অংশ: MasterLCRepository, _MasterLCValidationException
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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

  /// Transactionally-incremented sequence document backing [getMaxSl].
  DocumentReference<Map<String, dynamic>> get _counterDoc =>
      _db.collection(AppConstants.collectionCounters).doc('master_lc');

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

  /// Next available serial number (max stored `sl` + 1, or 1 when empty).
  ///
  /// SRS Rule 1: the Sl. is auto-generated. This method is the spec'd reader;
  /// [createWithTransaction] uses the transactionally-guarded counter document
  /// instead so two concurrent creates can never collide. Falls back to the
  /// stored maximum so the two sources are reconciled rather than drifting.
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
          : _int(snapshot.docs.first.data()['sl']);

      // Never hand out a value that collides with an existing record.
      if (maxStored > next) next = maxStored;
      return next + 1;
    } catch (_) {
      return 1;
    }
  }

  static int _int(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  @override
  Future<Either<String, List<String>>> getProjectList() async {
    try {
      final snapshot = await _collection.limit(1000).get();
      final projects =
          snapshot.docs
              .map((doc) => doc.data()['project']?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return Right(projects);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<String>>> getCompanyList() async {
    try {
      final snapshot = await _collection.limit(1000).get();
      final companies =
          snapshot.docs
              .map((doc) => doc.data()['company']?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return Right(companies);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> createWithTransaction(MasterLCEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> updateWithTransaction(MasterLCEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  /// Atomic write.
  ///
  /// Master LC is the root of the workflow chain, so it has no upstream balance
  /// to re-check; the transaction guarantees the document is created/updated
  /// atomically and that an update cannot resurrect a concurrently deleted
  /// record.
  Future<Either<String, void>> _writeWithTransaction(
    MasterLCEntity item, {
    required bool isUpdate,
  }) async {
    final ref = isUpdate && item.id != null
        ? _collection.doc(item.id)
        : _collection.doc();
    try {
      final data = MasterLCModel.fromEntity(item).toFirestore();
      data['id'] = ref.id;
      await _db.runTransaction<void>((transaction) async {
        if (isUpdate) {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw const _MasterLCValidationException(
              'Master LC no longer exists',
            );
          }
          // The Sl. is immutable once assigned: keep whatever is persisted.
          data['sl'] = _int(snapshot.data()?['sl']);
          transaction.update(ref, data);
          return;
        }

        // Create path: assign the next Sl. atomically.
        //
        // Firestore has no native auto-increment, so a counter document is
        // incremented inside the transaction. Firestore re-runs the transaction
        // on conflict, which makes the read-increment-write sequence atomic:
        // two concurrent creates can never receive the same Sl.
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
            : _int(latest.docs.first.data()['sl']);
        if (maxStored > lastAssigned) lastAssigned = maxStored;

        final nextSl = lastAssigned + 1;
        data['sl'] = nextSl;
        transaction.set(ref, data);
        transaction.set(_counterDoc, {'value': nextSl});
      });
      return const Right(null);
    } on _MasterLCValidationException catch (e) {
      return Left(e.message);
    } on FirebaseException catch (e) {
      return Left(
        '${isUpdate ? 'Failed to update' : 'Failed to create'}: ${e.message}',
      );
    } catch (_) {
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

/// Internal marker so a failed transaction validation is surfaced to the user
/// verbatim instead of being wrapped in a generic Firestore error message.
class _MasterLCValidationException implements Exception {
  const _MasterLCValidationException(this.message);
  final String message;
}

