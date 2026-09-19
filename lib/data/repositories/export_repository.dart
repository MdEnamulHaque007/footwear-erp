import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/export_entity.dart';
import '../../domain/repositories/i_export_repository.dart';
import '../models/export/export_model.dart';
import '../models/purchase_order/po_model.dart';

class ExportRepository implements IExportRepository {
  ExportRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(AppConstants.collectionExport);
  CollectionReference<Map<String, dynamic>> get _issueCollection =>
      _db.collection(AppConstants.collectionIssue);
  CollectionReference<Map<String, dynamic>> get _poCollection =>
      _db.collection(AppConstants.collectionPO);

  /// Keyset-pagination cursor: reset on page 0, advanced to the last doc read.
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  Future<Either<String, List<ExportModel>>> getExportList({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (page == 0) _lastDoc = null;
      var query = _collection.orderBy('exportDate', descending: true);
      if (page > 0 && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snapshot = await query.limit(limit).get();
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;
      return Right(snapshot.docs.map(ExportModel.fromSnapshot).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<ExportModel>>> byPoTag(String poTagNo) async {
    try {
      final snapshot = await _collection
          .where('tagNo', isEqualTo: poTagNo)
          .orderBy('sl')
          .get();
      return Right(snapshot.docs.map(ExportModel.fromSnapshot).toList());
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, ExportModel?>> byId(String id) async {
    try {
      final snapshot = await _collection.doc(id).get();
      return Right(snapshot.exists ? ExportModel.fromSnapshot(snapshot) : null);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, List<ExportModel>>> byLine({
    required String poNo,
    required String article,
    required String color,
  }) async {
    try {
      // Index-independent: Article and Color are filtered locally so the detail
      // view also works before composite indexes finish building in Firestore.
      final snapshot = await _collection
          .where('poNo', isEqualTo: poNo)
          .limit(1000)
          .get();
      final normalizedArticle = _normalize(article);
      final normalizedColor = _normalize(color);
      final entries =
          snapshot.docs
              .map(ExportModel.fromSnapshot)
              .where(
                (item) =>
                    _normalize(item.article) == normalizedArticle &&
                    _normalize(item.color) == normalizedColor,
              )
              .toList()
            ..sort((a, b) => b.exportDate.compareTo(a.exportDate));
      return Right(entries);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Distinct PO No list taken from the Issue entries.
  ///
  /// Export is only valid for a PO that has actually been issued.
  @override
  Future<Either<String, List<String>>> getIssueEntryPONoList() async {
    try {
      final snapshot = await _issueCollection.limit(1000).get();
      final poNos =
          snapshot.docs
              .map((doc) => _string(doc.data()['poNo']))
              .where((poNo) => poNo.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return Right(poNos);
    } on FirebaseException catch (e) {
      return Left('Database error: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Distinct Article + Color pairs recorded in the Issue entries of [poNo],
  /// deduped case-insensitively (first casing wins).
  @override
  Future<Either<String, List<IssueLine>>> getIssueEntryLines(
    String poNo,
  ) async {
    try {
      final snapshot = await _issueCollection
          .where('poNo', isEqualTo: poNo)
          .limit(1000)
          .get();
      final lines = <String, IssueLine>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final article = _string(data['article']);
        final color = _string(data['color']);
        if (article.isEmpty || color.isEmpty) continue;
        final key = '${article.toLowerCase()}|${color.toLowerCase()}';
        lines.putIfAbsent(
          key,
          () => IssueLine(article: article, color: color),
        );
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

  @override
  Future<Either<String, POModel?>> poByNo(String poNo) async {
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
  Future<int> getCumulativeIssueQty({
    required String poNo,
    required String article,
    required String color,
    required DateTime upToDate,
    String? excludeId,
  }) async {
    final snapshot = await _issueCollection
        .where('poNo', isEqualTo: poNo)
        .limit(1000)
        .get();
    final cutoff = DateTime(upToDate.year, upToDate.month, upToDate.day);
    return snapshot.docs
        .where((doc) => doc.id != excludeId)
        .where((doc) {
          final data = doc.data();
          return _normalize(data['article']) == _normalize(article) &&
              _normalize(data['color']) == _normalize(color);
        })
        .where((doc) {
          final date = _date(doc.data()['issueDate']);
          if (date == null) return true;
          return !DateTime(date.year, date.month, date.day).isAfter(cutoff);
        })
        .fold<int>(0, (total, doc) => total + _issueQuantity(doc.data()));
  }

  @override
  Future<int> getCumulativeExportQty({
    required String poNo,
    required String article,
    required String color,
    String? excludeId,
  }) async {
    final snapshot = await _collection
        .where('poNo', isEqualTo: poNo)
        .limit(1000)
        .get();
    return _cumulativeExport(
      snapshot.docs,
      article: article,
      color: color,
      excludingId: excludeId,
    );
  }

  @override
  Future<Either<String, void>> createWithTransaction(ExportEntity item) =>
      _writeWithTransaction(item, isUpdate: false);

  @override
  Future<Either<String, void>> updateWithTransaction(ExportEntity item) =>
      _writeWithTransaction(item, isUpdate: true);

  /// Validation + atomic write.
  ///
  /// The availability snapshot (Issue completed on or before the export date −
  /// Export already recorded for the same PO line) is computed with the
  /// date-filtered cumulative queries, validated, then the document is written
  /// inside a `runTransaction` that re-reads the persisted record, so a
  /// concurrent edit cannot silently over-consume the Issue balance.
  Future<Either<String, void>> _writeWithTransaction(
    ExportEntity item, {
    required bool isUpdate,
  }) async {
    final ref = isUpdate && item.id != null
        ? _collection.doc(item.id)
        : _collection.doc();
    try {
      final issueQty = await getCumulativeIssueQty(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        upToDate: item.exportDate,
      );
      final exportedQty = await getCumulativeExportQty(
        poNo: item.poNo,
        article: item.article,
        color: item.color,
        excludeId: ref.id,
      );

      final available = issueQty - exportedQty;
      if (item.quantity <= 0) {
        return const Left('Quantity must be greater than zero');
      }
      if (item.quantity > available) {
        return Left(
          'Export quantity exceeds available issue quantity '
          '(available: $available)',
        );
      }

      final data = ExportModel.fromEntity(item).toFirestore();
      await _db.runTransaction<void>((transaction) async {
        if (isUpdate) {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw const _ExportValidationException(
              'Export record no longer exists',
            );
          }
          transaction.update(ref, data);
        } else {
          transaction.set(ref, data);
        }
      });
      return const Right(null);
    } on _ExportValidationException catch (e) {
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
  Future<Either<String, void>> createExport(ExportEntity item) async {
    try {
      final ref = _collection.doc();
      final data = ExportModel.fromEntity(item).toFirestore();
      await ref.set(data);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Failed to create: ${e.message}');
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  @override
  Future<Either<String, void>> update(ExportEntity item) async {
    try {
      final data = ExportModel.fromEntity(item).toFirestore();
      data['updatedAt'] = Timestamp.now();
      await _collection.doc(item.id).update(data);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left('Failed to update: ${e.message}');
    } catch (_) {
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
    } catch (_) {
      return const Left('An unexpected error occurred');
    }
  }

  /// Sums Export records for one PO line, optionally skipping a document.
  static int _cumulativeExport(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String article,
    required String color,
    String? excludingId,
  }) {
    final normalizedArticle = _normalize(article);
    final normalizedColor = _normalize(color);
    return docs
        .where((doc) => doc.id != excludingId)
        .where((doc) {
          final data = doc.data();
          return _normalize(data['article']) == normalizedArticle &&
              _normalize(data['color']) == normalizedColor;
        })
        .fold<int>(0, (total, doc) => total + _exportQuantity(doc.data()));
  }

  static int _exportQuantity(Map<String, dynamic> data) =>
      _number(data['quantity'] ?? data['exportQuantity']);

  static int _issueQuantity(Map<String, dynamic> data) =>
      _number(data['quantity'] ?? data['issueQuantity']);

  static int _number(Object? value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString().trim() ?? '') ?? 0;

  static String _normalize(Object? value) =>
      value?.toString().trim().toLowerCase() ?? '';

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Internal marker so a failed transaction validation is surfaced to the user
/// verbatim instead of being wrapped in a generic Firestore error message.
class _ExportValidationException implements Exception {
  const _ExportValidationException(this.message);
  final String message;
}


