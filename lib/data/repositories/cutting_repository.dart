import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/cutting_entity.dart';
import '../../domain/repositories/i_cutting_repository.dart';
import '../models/cutting/cutting_model.dart';
import '../models/purchase_order/po_model.dart';
import '../models/master_lc/master_lc_model.dart';


class CuttingRepository implements ICuttingRepository {
  CuttingRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(AppConstants.collectionCutting);
  CollectionReference<Map<String, dynamic>> get _poCollection =>
      _db.collection(AppConstants.collectionPO);
  CollectionReference<Map<String, dynamic>> get _masterLcCollection =>
      _db.collection(AppConstants.collectionMasterLC);

  /// Distinct Article + Color pairs recorded in the PO line items of [poNo].
  @override
  Future<Either<String, List<CuttingLine>>> getPOLines(String poNo) async {
    try {
      final snapshot = await _poCollection
          .where('poNo', isEqualTo: poNo)
          .limit(10)
          .get();
      final lines = <String, CuttingLine>{};
      for (final doc in snapshot.docs) {
        final items = doc.data()['lineItems'];
        if (items is! List) continue;
        for (final raw in items) {
          if (raw is! Map) continue;
          final article = raw['article']?.toString().trim() ?? '';
          final color = raw['color']?.toString().trim() ?? '';
          if (article.isEmpty || color.isEmpty) continue;
          final key = '${article.toLowerCase()}|${color.toLowerCase()}';
          lines.putIfAbsent(
            key,
            () => CuttingLine(article: article, color: color),
          );
        }
      }
      final result = lines.values.toList()
        ..sort((a, b) {
          final byArticle = a.article.toLowerCase().compareTo(
            b.article.toLowerCase(),
          );
          return byArticle != 0
              ? byArticle
              : a.color.toLowerCase().compareTo(b.color.toLowerCase());
        });
      return Right(result);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Keyset-pagination cursor: reset on page 0, advanced to the last doc read.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  Future<Either<String, List<CuttingModel>>> getCuttingList({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (page == 0) _lastDoc = null;
      var query = _collection.orderBy('cuttingDate', descending: true);
      if (page > 0 && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snapshot = await query.limit(limit).get();
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;

      final list = snapshot.docs.map(CuttingModel.fromSnapshot).toList();
      return Right(await enrichCuttingsWithPO(list));
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (e) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, String>> getNextVoucherNo(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyyMMdd').format(date);
      final prefix = 'CUT-$dateStr-';
      final snapshot = await _collection
          .where('voucherNo', isGreaterThanOrEqualTo: prefix)
          .where('voucherNo', isLessThan: '${prefix}ZZZ')
          .orderBy('voucherNo', descending: true)
          .limit(1)
          .get();

      var nextSerial = 1;
      if (snapshot.docs.isNotEmpty) {
        final lastVoucher =
            snapshot.docs.first.data()['voucherNo']?.toString() ?? '';
        final lastSerial = int.tryParse(lastVoucher.split('-').last) ?? 0;
        nextSerial = lastSerial + 1;
      }
      return Right('$prefix${nextSerial.toString().padLeft(3, '0')}');
    } catch (error) {
      return Left('Failed to generate voucher: $error');
    }
  }

  @override
  Future<Either<String, List<CuttingModel>>> byPoTag(String poTagNo) async {
    try {
      final s = await _collection
          .where('tagNo', isEqualTo: poTagNo)
          .orderBy('cuttingDate', descending: true)
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
      if (!snapshot.exists) return const Right(null);
      final item = CuttingModel.fromSnapshot(snapshot);
      final enriched = await enrichCuttingsWithPO([item]);
      return Right(enriched.single);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Fills legacy Cutting records from their matching PO and PO line item.
  /// Unit price is intentionally not restored because Cutting no longer stores
  /// financial values.
  Future<List<CuttingModel>> enrichCuttingsWithPO(
    List<CuttingModel> items,
  ) async {
    final missing = items
        .where((item) => item.poNo.isNotEmpty)
        .where((item) => item.tagNo.isEmpty || item.poQuantity == 0)
        .toList();
    if (missing.isEmpty) return items;

    final poNos = missing.map((item) => item.poNo).toSet().toList();
    final poByNo = <String, POModel>{};
    for (var start = 0; start < poNos.length; start += 30) {
      final batch = poNos.skip(start).take(30).toList();
      final snapshot = await _poCollection
          .where('poNo', whereIn: batch)
          .get();
      for (final document in snapshot.docs) {
        final po = POModel.fromSnapshot(document);
        poByNo.putIfAbsent(po.poNo, () => po);
      }
    }

    return items.map((item) {
      // Continue enrichment even when tag/quantity already exist because
      // legacy records may still be missing company/project.
      final basePo = poByNo[item.poNo];
      if (basePo == null) {
        debugPrint('Cutting PO not found: \${item.poNo}');
        return item;
      }

      // Some legacy/imported PO documents contain the correct PO number/tag
      // but have blank company/project fields. Master LC is the authoritative
      // source for those two fields, keyed by the same Tag No.
      final po = await _enrichPOHeaderFromMasterLc(basePo);
      final matchingLines = po.effectiveLineItems.where((line) {
        return _normalize(line.article) == _normalize(item.article) &&
            _normalize(line.color) == _normalize(item.color);
      }).toList();
      final line = matchingLines.isEmpty ? null : matchingLines.first;
      final poQuantity = item.poQuantity == 0
          ? (line?.poQuantity ?? 0)
          : item.poQuantity;
      final tagNo = item.tagNo.isEmpty ? po.tagNo : item.tagNo;
      return CuttingModel.fromEntity(
        item.copyWith(
          tagNo: tagNo,
          poTagNo: item.tagNo.isEmpty ? tagNo : item.tagNo,
          company: item.company.isEmpty ? po.company : item.company,
          project: item.project.isEmpty ? po.project : item.project,
          poQuantity: poQuantity,
        ),
      );
    }).toList();
  }

  Future<POModel> _enrichPOHeaderFromMasterLc(POModel po) async {
    if (po.company.isNotEmpty && po.project.isNotEmpty) return po;
    if (po.tagNo.isEmpty) return po;

    try {
      final snapshot = await _masterLcCollection
          .where('tagNo', isEqualTo: po.tagNo)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return po;

      final master = MasterLCModel.fromSnapshot(snapshot.docs.first);
      return POModel.fromEntity(
        po.copyWith(
          company: po.company.isEmpty ? master.company : po.company,
          project: po.project.isEmpty ? master.project : po.project,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint('Master LC lookup failed for PO ${po.poNo}: ${e.message}');
      return po;
    } catch (e) {
      debugPrint('Master LC lookup failed for PO ${po.poNo}: $e');
      return po;
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
      final snapshot = await _poCollection.orderBy('poNo').limit(1000).get();
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
  Future<Either<String, void>> createWithTransaction(CuttingEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> updateWithTransaction(CuttingEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  /// Atomic create/update for a Cutting entry.
  ///
  /// Business rule: Cutting **may exceed** the PO line quantity (soft-limit).
  /// Excess cuts are allowed so extra production after order completion can be
  /// recorded. Only non-positive quantities are rejected. Sibling reads still
  /// self-exclude the document being edited for consistent cumulative totals.
  Future<Either<String, void>> _writeWithTransaction(
    CuttingEntity item, {
    required bool isUpdate,
  }) async {
    final ref = isUpdate && item.id != null
        ? _collection.doc(item.id)
        : _collection.doc();
    try {
      final data = CuttingModel.fromEntity(item).toFirestore();
      await _db.runTransaction<void>((transaction) async {
        if (item.cuttingQuantity <= 0) {
          throw const _CuttingValidationException(
            'Quantity must be greater than zero',
          );
        }

        if (isUpdate) {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw const _CuttingValidationException(
              'Cutting record no longer exists',
            );
          }
          transaction.update(ref, data);
          return;
        }

        transaction.set(ref, data);
      });
      return const Right(null);
    } on _CuttingValidationException catch (e) {
      return Left(e.message);
    } on FirebaseException catch (e) {
      return Left(
        '${isUpdate ? 'Failed to update' : 'Failed to create'}: ${e.message}',
      );
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Reads the PO quantity for the line being cut. PO documents store the line
  /// quantity either in `lineItems` or in the legacy flat `poQuantity` field.
  static int _lineQuantity(Map<String, dynamic> po) {
    final items = po['lineItems'];
    if (items is List && items.isNotEmpty) {
      return items.fold<int>(
        0,
        (total, raw) =>
            total + _number(raw is Map ? raw['poQuantity'] : null),
      );
    }
    return _number(po['poQuantity'] ?? po['quantity']);
  }

  static int _number(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  static String _normalize(Object? value) =>
      value?.toString().trim().toLowerCase() ?? '';

  @override
  Future<Either<String, void>> createCutting(CuttingEntity item) async {
    try {
      final ref = _collection.doc();
      final data = CuttingModel.fromEntity(item).toFirestore();
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
        .where('tagNo', isEqualTo: poTagNo)
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

/// Internal marker so a failed transaction validation is surfaced to the user
/// verbatim instead of being wrapped in a generic Firestore error message.
class _CuttingValidationException implements Exception {
  const _CuttingValidationException(this.message);
  final String message;
}

