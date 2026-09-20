import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';

import '../../core/failure.dart';
import '../models/cutting_model.dart';

abstract class CuttingRepository {
  Future<Either<Failure, List<Cutting>>> getAll({
    String? poNo,
    DateTime? from,
    DateTime? to,
  });

  Stream<List<Cutting>> watchAll({
    String? poNo,
    DateTime? from,
    DateTime? to,
  });

  Future<Cutting?> getById(String docId);

  Future<void> create(Cutting cutting);

  Future<void> update(Cutting cutting);

  Future<void> softDelete(String docId);

  Future<Either<Failure, String>> getNextVoucherNo(DateTime date);
}

class FirestoreCuttingRepository implements CuttingRepository {
  FirestoreCuttingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('cuttings');

  @override
  Future<Either<Failure, List<Cutting>>> getAll({
    String? poNo,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection;
      if (poNo != null && poNo.trim().isNotEmpty) {
        query = query.where('poNo', isEqualTo: poNo.trim());
      }
      if (from != null) {
        query = query.where(
          'cuttingDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        );
      }
      if (to != null) {
        query = query.where(
          'cuttingDate',
          isLessThanOrEqualTo: Timestamp.fromDate(to),
        );
      }

      final snapshot = await query.get();
      final items = snapshot.docs.map(Cutting.fromFirestore).toList()
        ..sort((a, b) => b.cuttingDate.compareTo(a.cuttingDate));
      return Right(items);
    } on FirebaseException catch (e) {
      return Left(Failure(e.message ?? 'Firestore error', code: e.code));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Stream<List<Cutting>> watchAll({
    String? poNo,
    DateTime? from,
    DateTime? to,
  }) {
    Query<Map<String, dynamic>> query = _collection;
    if (poNo != null && poNo.trim().isNotEmpty) {
      query = query.where('poNo', isEqualTo: poNo.trim());
    }
    if (from != null) {
      query = query.where(
        'cuttingDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    }
    if (to != null) {
      query = query.where(
        'cuttingDate',
        isLessThanOrEqualTo: Timestamp.fromDate(to),
      );
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map(Cutting.fromFirestore).toList()
        ..sort((a, b) => b.cuttingDate.compareTo(a.cuttingDate));
      return items;
    });
  }

  @override
  Future<Cutting?> getById(String docId) async {
    try {
      final snapshot = await _collection.doc(docId).get();
      if (!snapshot.exists) return null;
      return Cutting.fromFirestore(snapshot);
    } on FirebaseException catch (e) {
      throw Failure(e.message ?? 'Firestore error', code: e.code);
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  @override
  Future<Either<Failure, String>> getNextVoucherNo(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyyMMdd').format(date);
      final prefix = 'CUT-$dateStr-';
      final snapshot = await _collection
          .where('voucherNo', isGreaterThanOrEqualTo: prefix)
          .where('voucherNo', isLessThan: prefix + 'ZZZ')
          .orderBy('voucherNo', descending: true)
          .limit(1)
          .get();

      var nextSerial = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastVoucher = snapshot.docs.first.data()['voucherNo']?.toString() ?? '';
        final lastSerial = int.tryParse(lastVoucher.split('-').last) ?? 0;
        nextSerial = lastSerial + 1;
      }

      return Right('$prefix${nextSerial.toString().padLeft(3, '0')}');
    } on FirebaseException catch (e) {
      return Left(Failure(e.message ?? 'Failed to generate voucher', code: e.code));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<void> create(Cutting cutting) async {
    try {
      final now = DateTime.now();
      final prepared = cutting.copyWith(
        createdAt: now,
        updatedAt: now,
        source: cutting.source.isEmpty ? 'manual' : cutting.source,
        syncStatus: cutting.syncStatus.isEmpty ? 'synced' : cutting.syncStatus,
      );
      final docId = _buildDocId(prepared);
      final ref = _collection.doc(docId);
      if ((await ref.get()).exists) {
        throw const Failure('A cutting record already exists for this date, PO, article and color.');
      }
      await ref.set(prepared.toFirestore());
    } on FirebaseException catch (e) {
      throw Failure(e.message ?? 'Firestore error', code: e.code);
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  @override
  Future<void> update(Cutting cutting) async {
    try {
      final targetId = _buildDocId(cutting);
      var existing = await _collection.doc(targetId).get();
      if (!existing.exists) {
        final matches = await _collection
            .where('voucherNo', isEqualTo: cutting.voucherNo.trim())
            .limit(1)
            .get();
        if (matches.docs.isNotEmpty) existing = matches.docs.first;
      }
      if (!existing.exists) {
        throw const Failure('Cutting record not found');
      }

      final existingCutting = Cutting.fromFirestore(existing);
      final prepared = cutting.copyWith(
        createdAt: existingCutting.createdAt,
        updatedAt: DateTime.now(),
      );
      final targetRef = _collection.doc(targetId);

      await _firestore.runTransaction<void>((transaction) async {
        if (existing.reference.path != targetRef.path) {
          transaction.delete(existing.reference);
        }
        transaction.set(targetRef, prepared.toFirestore());
      });
    } on Failure {
      rethrow;
    } on FirebaseException catch (e) {
      throw Failure(e.message ?? 'Firestore error', code: e.code);
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  @override
  Future<void> softDelete(String docId) async {
    try {
      final sourceRef = _collection.doc(docId);
      final archiveRef = _firestore.collection('cuttings_deleted').doc(docId);
      await _firestore.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(sourceRef);
        if (!snapshot.exists) {
          throw const Failure('Cutting record not found');
        }
        transaction.set(archiveRef, snapshot.data()!);
        transaction.delete(sourceRef);
      });
    } on Failure {
      rethrow;
    } on FirebaseException catch (e) {
      throw Failure(e.message ?? 'Firestore error', code: e.code);
    } catch (e) {
      throw Failure(e.toString());
    }
  }

  String _buildDocId(Cutting cutting) {
    final date = DateFormat('yyyyMMdd').format(cutting.cuttingDate);
    return [
      date,
      _sanitize(cutting.poNo),
      _sanitize(cutting.article),
      _sanitize(cutting.color),
    ].join('_');
  }

  String _sanitize(String value) {
    final sanitized = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');
    return sanitized.isEmpty ? '-' : sanitized;
  }
}
