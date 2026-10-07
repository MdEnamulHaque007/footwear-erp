/// ============================================================================
/// ফাইল: lib/data/repositories/po_repository.dart
/// স্তর: Data Repository | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common data query, transaction, pagination ও persistence বাস্তবায়ন করে।
/// প্রধান অংশ: PORepository, _POValidationException
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import '../../core/services/activity/activity_log_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/firebase/firebase_cloud_function_service.dart';

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
    return ActivityLogService.instance.trackRead<Either<String, List<POModel>>>(
      module: 'purchase_order',
      operation: 'getPOList',
      documentId: '',
      body: () async {
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
      },
    );
  }

  @override
  Future<Either<String, List<POModel>>> byTag(String tag) {
    return ActivityLogService.instance.trackRead<Either<String, List<POModel>>>(
      module: 'purchase_order',
      operation: 'byTag',
      documentId: '',
      body: () async {
        return guard(() async {
          final snapshot = await _collection
              .where('tagNo', isEqualTo: tag)
              .orderBy('sl')
              .get();
          return snapshot.docs.map((doc) => POModel.fromSnapshot(doc)).toList();
        }, prefix: 'Database error');
      },
    );
  }

  @override
  Future<Either<String, POModel?>> byId(String id) async {
    return ActivityLogService.instance.trackRead<Either<String, POModel?>>(
      module: 'purchase_order',
      operation: 'byId',
      documentId: id,
      body: () async {
        try {
          final snapshot = await _collection.doc(id).get();
          return Right(snapshot.exists ? POModel.fromSnapshot(snapshot) : null);
        } on FirebaseException catch (e) {
          return Left('Database error: ${e.message}');
        } catch (_) {
          return const Left('An unexpected error occurred');
        }
      },
    );
  }

  /// Next available serial number (max stored `sl` + 1, or 1 when empty).
  ///
  /// SRS Rule 1: the Sl. is auto-generated. Reads the counter document *and* the
  /// stored maximum, returning the higher of the two so legacy rows written
  /// before the counter existed cannot cause a collision.
  @override
  Future<int> getMaxSl() async {
    return ActivityLogService.instance.trackRead<int>(
      module: 'purchase_order',
      operation: 'getMaxSl',
      documentId: '',
      body: () async {
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
      },
    );
  }

  /// Whether [poNo] is free. PO No is unique **globally** across all tags.
  @override
  Future<bool> isPoNoUnique(String poNo, {String? excludeId}) async {
    return ActivityLogService.instance.trackRead<bool>(
      module: 'purchase_order',
      operation: 'isPoNoUnique',
      documentId: '',
      body: () async {
        final trimmed = poNo.trim();
        if (trimmed.isEmpty) return true;
        final snapshot = await _collection
            .where('poNo', isEqualTo: trimmed)
            .limit(10)
            .get();
        return snapshot.docs.every((doc) => doc.id == excludeId);
      },
    );
  }

  @override
  Future<Either<String, void>> createWithTransaction(POEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> updateWithTransaction(POEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  /// Authorization, quantity/date checks and writes run in one server transaction.
  Future<Either<String, void>> _writeWithTransaction(
    POEntity item, {
    required bool isUpdate,
  }) async {
    if (isUpdate && (item.id == null || item.id!.isEmpty)) {
      return const Left('Record ID is required for update');
    }
    final id = isUpdate ? item.id! : _collection.doc().id;
    return FirebaseCloudFunctionService.instance.mutate(
      collection: 'purchase_orders',
      action: isUpdate ? 'update' : 'create',
      id: id,
      data: POModel.fromEntity(item).toFirestore(),
    );
  }

  static int _number(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  static double _double(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().trim() ?? '') ?? 0;

  @override
  Future<Either<String, void>> createPO(POEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> update(POEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  @override
  Future<Either<String, void>> delete(String id) => FirebaseCloudFunctionService
      .instance
      .mutate(collection: 'purchase_orders', action: 'delete', id: id);
}
